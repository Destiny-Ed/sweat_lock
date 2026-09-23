import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';

/// Android blocking via Accessibility — mirrors iOS immediate / timed modes.
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
  String? get currentlyBlockedPackage => _currentlyBlockedPackage;

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

  /// Periodic tick so timed mode locks even without new accessibility events.
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
        packageName.contains('flutter_accessibility')) {
      return;
    }

    if (event.eventType != EventType.typeWindowStateChanged) return;

    // Leaving previous focused app → freeze its session timer
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

  Future<void> _evaluatePackage(String packageName, {bool fromTick = false}) async {
    final matched = _matchBlocked(packageName);

    if (matched == null) {
      if (_currentlyBlockedPackage == packageName) {
        await hideBlockOverlay();
        _currentlyBlockedPackage = null;
      }
      return;
    }

    // Temporary unlock after workout / reading
    if (HiveService.isPackageTemporarilyUnlocked(packageName)) {
      await hideBlockOverlay();
      _currentlyBlockedPackage = null;
      return;
    }

    final mode = HiveService.getBlockMode();

    if (mode == 'immediate') {
      _currentlyBlockedPackage = packageName;
      await showBlockOverlay();
      return;
    }

    // --- Timed free window (active use only) ---
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
      _currentlyBlockedPackage = packageName;
      await _notify(
        id: 2001,
        title: 'SweatLock — ${matched.appName} locked',
        body:
            'Free time on ${matched.appName} is up. Complete a workout or read to unlock.',
      );
      await showBlockOverlay();
      return;
    }

    final warnAt = (freeMs - warnMs).clamp(0, freeMs);
    if (used >= warnAt && !HiveService.wasWarned(packageName)) {
      await HiveService.setWarned(packageName, true);
      await _notify(
        id: 2002,
        title: 'SweatLock',
        body:
            'Almost out of free time on ${matched.appName}.',
      );
    }

    // Still in free window
    if (_currentlyBlockedPackage == packageName) {
      await hideBlockOverlay();
      _currentlyBlockedPackage = null;
    }
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

  /// After successful workout/reading — temporary unlock + reset usage.
  Future<void> grantTemporaryUnlock(
    String packageName, {
    int? minutes,
  }) async {
    final mins = minutes ?? HiveService.getUnlockDurationMinutes();
    final until = DateTime.now().add(Duration(minutes: mins));
    await HiveService.setPackageUnlockUntil(packageName, until);
    await HiveService.resetPackageUsage(packageName);
    await hideBlockOverlay();
    _currentlyBlockedPackage = null;
    debugPrint('Unlocked $packageName for $mins min');
  }

  Future<void> grantCurrentUnlock({int? minutes}) async {
    final pkg = _currentlyBlockedPackage;
    if (pkg != null) {
      await grantTemporaryUnlock(pkg, minutes: minutes);
    } else {
      // Unlock all active blocked packages (fallback after in-app workout)
      final mins = minutes ?? HiveService.getUnlockDurationMinutes();
      for (final a in HiveService.getBlockedApps().where((x) => x.isActive)) {
        if (a.packageName.isEmpty) continue;
        await HiveService.setPackageUnlockUntil(
          a.packageName,
          DateTime.now().add(Duration(minutes: mins)),
        );
        await HiveService.resetPackageUsage(a.packageName);
      }
      await hideBlockOverlay();
      _currentlyBlockedPackage = null;
    }
  }

  void dispose() {
    stopListening();
  }
}
