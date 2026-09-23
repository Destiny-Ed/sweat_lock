import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/services/schedule_service.dart';

class BlockingService {
  static BlockingService? _instance;
  static BlockingService get instance => _instance ??= BlockingService._();

  BlockingService._();

  StreamSubscription<AccessibilityEvent>? _subscription;
  bool _isListening = false;
  String? _currentlyBlockedPackage;
  String? _focusedPackage;
  Timer? _tickTimer;

  static const _notifChannel = MethodChannel('sweatlock/android_notify');

  bool get isListening => _isListening;
  String? get currentlyBlockedPackage =>
      _currentlyBlockedPackage ?? HiveService.getLastBlockedPackage();

  Future<void> checkAndStart() async {
    if (!Platform.isAndroid) return;
    final enabled = await isAccessibilityEnabled();
    if (enabled) await startListening();
  }

  Future<bool> isAccessibilityEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    } catch (e) {
      debugPrint('isAccessibilityEnabled error: $e');
      return false;
    }
  }

  Future<bool> requestAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterAccessibilityService.requestAccessibilityPermission();
    } catch (e) {
      debugPrint('requestAccessibilityPermission error: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (!Platform.isAndroid || _isListening) return;

    final enabled = await isAccessibilityEnabled();
    if (!enabled) {
      debugPrint('Accessibility not enabled');
      return;
    }

    _subscription?.cancel();
    _subscription = FlutterAccessibilityService.accessStream.listen(
      _onAccessibilityEvent,
      onError: (e) => debugPrint('Accessibility stream error: $e'),
    );
    _isListening = true;
    _startTick();
    debugPrint('BlockingService started');
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _tickTimer?.cancel();
    _isListening = false;
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final pkg = _focusedPackage;
      if (pkg != null) {
        unawaited(_evaluatePackage(pkg, fromTick: true));
      }
    });
  }

  Future<void> _onAccessibilityEvent(AccessibilityEvent event) async {
    final packageName = event.packageName;
    if (packageName == null || packageName.isEmpty) return;

    if (packageName.contains('sweat_lock') ||
        packageName.contains('flutter_accessibility') ||
        packageName.contains('com.sweatlock')) {
      return;
    }

    if (event.eventType != EventType.typeWindowStateChanged) return;

    if (_focusedPackage != null && _focusedPackage != packageName) {
      await _pauseSession(_focusedPackage!);
    }

    _focusedPackage = packageName;
    await _evaluatePackage(packageName);
  }

  Future<void> _pauseSession(String package) async {
    final start = HiveService.getSessionStartMs(package);
    if (start == null) return;
    final extra = DateTime.now().millisecondsSinceEpoch - start;
    final total = HiveService.getUsageMs(package) + extra;
    await HiveService.setUsageMs(package, total);
    await HiveService.setSessionStartMs(package, null);
  }

  BlockedApp? _matchBlocked(String packageName) {
    final blockedApps =
        HiveService.getBlockedApps().where((a) => a.isActive).toList();
    for (final a in blockedApps) {
      if (a.packageName.isEmpty) continue;
      if (a.packageName == packageName ||
          packageName.contains(a.packageName) ||
          a.packageName.contains(packageName)) {
        return a;
      }
    }
    return null;
  }

  Future<void> _evaluatePackage(String packageName,
      {bool fromTick = false}) async {
    final matched = _matchBlocked(packageName);

    if (matched == null) {
      if (_currentlyBlockedPackage == packageName) {
        await hideBlockOverlay();
        _currentlyBlockedPackage = null;
      }
      return;
    }

    if (HiveService.isPackageTemporarilyUnlocked(packageName)) {
      await hideBlockOverlay();
      if (_currentlyBlockedPackage == packageName) {
        _currentlyBlockedPackage = null;
      }
      return;
    }

    // Focus schedule forces hard lock (ignore free window).
    final mode = ScheduleService.instance.effectiveBlockMode();

    if (mode == 'immediate') {
      if (ScheduleService.instance.isInFocusWindow && fromTick == false) {
        // optional: one-shot schedule notification handled lightly
      }
      await _lockPackage(packageName, matched);
      return;
    }

    if (HiveService.getSessionStartMs(packageName) == null) {
      await HiveService.setSessionStartMs(
        packageName,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    final freeMs = HiveService.getFreeMinutes() * 60 * 1000;
    final warnMs = HiveService.getWarningMinutes() * 60 * 1000;
    final used = HiveService.liveUsageMs(packageName);

    if (used >= freeMs) {
      await _notify(
        id: 2001,
        title: 'SweatLock — ${matched.appName} locked',
        body:
            'Free window ended. Workout, walk, or read + quiz to unlock ${matched.appName} only.',
      );
      await _lockPackage(packageName, matched);
      return;
    }

    final warnAt = (freeMs - warnMs).clamp(0, freeMs);
    if (used >= warnAt && !HiveService.wasWarned(packageName)) {
      await HiveService.setWarned(packageName, true);
      await _notify(
        id: 2002,
        title: 'SweatLock',
        body: 'Almost out of free time on ${matched.appName}.',
      );
    }

    if (_currentlyBlockedPackage == packageName) {
      await hideBlockOverlay();
      _currentlyBlockedPackage = null;
    }
  }

  Future<void> _lockPackage(String packageName, BlockedApp matched) async {
    _currentlyBlockedPackage = packageName;
    await HiveService.setLastBlockedPackage(packageName);
    await HiveService.setLastBlockedAppId(matched.id);
    await showBlockOverlay();
  }

  Future<void> _notify({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!HiveService.getNotificationsEnabled()) return;
    try {
      await _notifChannel.invokeMethod('show', {
        'id': id,
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('notify error: $e');
    }
  }

  Future<void> showBlockOverlay() async {
    try {
      await FlutterAccessibilityService.showOverlayWindow();
    } catch (e) {
      debugPrint('showBlockOverlay error: $e');
    }
  }

  Future<void> hideBlockOverlay() async {
    try {
      await FlutterAccessibilityService.hideOverlayWindow();
    } catch (e) {
      debugPrint('hideBlockOverlay error: $e');
    }
  }

  Future<void> grantTemporaryUnlock(
    String packageName, {
    int? minutes,
  }) async {
    if (packageName.isEmpty) return;
    final mins = minutes ?? HiveService.getUnlockDurationMinutes();
    final until = DateTime.now().add(Duration(minutes: mins));
    await HiveService.setPackageUnlockUntil(packageName, until);
    await HiveService.resetPackageUsage(packageName);
    await hideBlockOverlay();
    if (_currentlyBlockedPackage == packageName) {
      _currentlyBlockedPackage = null;
    }
  }

  Future<void> grantUnlockForAppId(String? appId, {int? minutes}) async {
    String? package;
    if (appId != null && appId.isNotEmpty) {
      for (final a in HiveService.getBlockedApps()) {
        if (a.id == appId && a.packageName.isNotEmpty) {
          package = a.packageName;
          break;
        }
      }
    }
    package ??= _currentlyBlockedPackage;
    package ??= HiveService.getLastBlockedPackage();
    if (package == null || package.isEmpty) {
      await hideBlockOverlay();
      return;
    }
    await grantTemporaryUnlock(package, minutes: minutes);
  }

  Future<void> grantCurrentUnlock({int? minutes}) async {
    await grantUnlockForAppId(HiveService.getLastBlockedAppId(), minutes: minutes);
  }

  Future<void> grantUnlockAll({int? minutes}) async {
    final mins = minutes ?? HiveService.getUnlockDurationMinutes();
    final until = DateTime.now().add(Duration(minutes: mins));
    for (final a in HiveService.getBlockedApps().where((x) => x.isActive)) {
      if (a.packageName.isEmpty) continue;
      await HiveService.setPackageUnlockUntil(a.packageName, until);
      await HiveService.resetPackageUsage(a.packageName);
    }
    await hideBlockOverlay();
    _currentlyBlockedPackage = null;
  }

  void dispose() {
    stopListening();
  }
}
