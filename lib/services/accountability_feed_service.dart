import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:uuid/uuid.dart';

enum AccountabilityEventType { win, fail, streak, emergency }

/// Queues public accountability events. Until backend ships, offers share sheet.
class AccountabilityFeedService {
  AccountabilityFeedService._();
  static final instance = AccountabilityFeedService._();

  /// Call after successful workout / steps / reading quiz.
  Future<void> recordWin({
    required String appName,
    required String challenge, // e.g. "25 push-ups"
    String? displayName,
  }) async {
    final mode = HiveService.getPublicAccountabilityMode();
    if (mode == 'off') return;

    final text = _winCopy(
      appName: appName,
      challenge: challenge,
      displayName: displayName ?? HiveService.getPublicDisplayName(),
    );
    await _enqueue(
      type: AccountabilityEventType.win,
      text: text,
      meta: {'appName': appName, 'challenge': challenge},
    );
  }

  /// Call when free window expires and user did not complete a challenge
  /// (doomscroll / dismiss). Only if mode is wins_and_fails.
  Future<void> recordFail({
    required String appName,
    int? usageMinutes,
  }) async {
    final mode = HiveService.getPublicAccountabilityMode();
    if (mode != 'wins_and_fails') return;

    // Rate limit: one fail post per calendar day
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month}-${today.day}';
    if (HiveService.getLastFailPostDay() == key) {
      debugPrint('Fail post rate-limited for $key');
      return;
    }

    final text = _failCopy(
      appName: appName,
      usageMinutes: usageMinutes,
      displayName: HiveService.getPublicDisplayName(),
    );
    await _enqueue(
      type: AccountabilityEventType.fail,
      text: text,
      meta: {
        'appName': appName,
        if (usageMinutes != null) 'usageMinutes': usageMinutes,
      },
    );
    await HiveService.setLastFailPostDay(key);
  }

  Future<void> _enqueue({
    required AccountabilityEventType type,
    required String text,
    Map<String, dynamic>? meta,
  }) async {
    final id = const Uuid().v4();
    final event = {
      'id': id,
      'type': type.name,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
      'meta': meta ?? {},
      'posted': false,
    };
    await HiveService.addAccountabilityEvent(event);
    debugPrint('Accountability queued [${type.name}]: $text');

    // Immediate soft share if user enabled “prompt after win”
    if (type == AccountabilityEventType.win &&
        HiveService.getPromptShareOnWin()) {
      try {
        await Share.share(text, subject: 'SweatLock');
      } catch (e) {
        debugPrint('Share sheet error: $e');
      }
    }
  }

  /// Manual share of the latest queued win (success screen button).
  Future<void> shareText(String text) async {
    try {
      await Share.share(text, subject: 'SweatLock');
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  String buildWinShareText({
    required String appName,
    required String challenge,
  }) {
    return _winCopy(
      appName: appName,
      challenge: challenge,
      displayName: HiveService.getPublicDisplayName(),
    );
  }

  String _winCopy({
    required String appName,
    required String challenge,
    required String displayName,
  }) {
    final name = displayName.isEmpty ? 'Someone' : displayName;
    final showApp = HiveService.getPublicShowAppNames();
    final target = showApp ? appName : 'a locked app';
    return '🔥 $name just earned $target with $challenge. '
        'Screen time earned, not stolen. #SweatLock';
  }

  String _failCopy({
    required String appName,
    int? usageMinutes,
    required String displayName,
  }) {
    final name = displayName.isEmpty ? 'Someone' : displayName;
    final showApp = HiveService.getPublicShowAppNames();
    final target = showApp ? appName : 'a feed';
    final mins = usageMinutes != null ? ' (~$usageMinutes min)' : '';
    return '⏳ $name let the free window run out on $target$mins — still locked. '
        'Earn it or leave it. #SweatLock';
  }

  /// Later: flush queue to backend → brand @SweatLock posts.
  Future<void> flushQueueToBackend() async {
    // Placeholder — wire to Node API when ready.
    final pending = HiveService.getPendingAccountabilityEvents();
    if (pending.isEmpty) return;
    debugPrint('Would POST ${pending.length} accountability events to backend');
  }
}
