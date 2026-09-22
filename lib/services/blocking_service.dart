import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';

/// Handles Android app blocking via Accessibility Service.
/// iOS uses a separate soft-nudge path (Phase 4).
class BlockingService {
  static BlockingService? _instance;
  static BlockingService get instance => _instance ??= BlockingService._();

  BlockingService._();

  StreamSubscription<AccessibilityEvent>? _subscription;
  bool _isListening = false;
  String? _currentlyBlockedPackage;
  DateTime? _lastUnlockTime;

  /// Temporary unlocks: packageName -> unlock expiry
  final Map<String, DateTime> _temporaryUnlocks = {};

  bool get isListening => _isListening;

  /// Check if accessibility permission is granted
  Future<bool> isAccessibilityEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    } catch (e) {
      debugPrint('isAccessibilityEnabled error: $e');
      return false;
    }
  }

  /// Request user to enable accessibility service
  Future<bool> requestAccessibilityPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await FlutterAccessibilityService.requestAccessibilityPermission();
    } catch (e) {
      debugPrint('requestAccessibilityPermission error: $e');
      return false;
    }
  }

  /// Start listening for app open events
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
    debugPrint('BlockingService started listening');
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }

  void _onAccessibilityEvent(AccessibilityEvent event) async {
    final packageName = event.packageName;
    if (packageName == null || packageName.isEmpty) return;

    // Ignore our own app
    if (packageName.contains('sweat_lock') ||
        packageName.contains('flutter_accessibility')) {
      return;
    }

    // Only care about window state changes (app opened / focused)
    if (event.eventType != EventType.typeWindowStateChanged) return;

    final blockedApps = HiveService.getBlockedApps()
        .where((a) => a.isActive)
        .toList();

    final matched = blockedApps.cast<BlockedApp?>().firstWhere(
          (a) => a!.packageName == packageName ||
              packageName.contains(a.packageName),
          orElse: () => null,
        );

    if (matched == null) {
      // Not a blocked app — hide overlay if showing
      if (_currentlyBlockedPackage != null) {
        await hideBlockOverlay();
        _currentlyBlockedPackage = null;
      }
      return;
    }

    // Check temporary unlock
    final unlockExpiry = _temporaryUnlocks[packageName];
    if (unlockExpiry != null && DateTime.now().isBefore(unlockExpiry)) {
      return; // Still unlocked
    }

    // Block it
    _currentlyBlockedPackage = packageName;
    await showBlockOverlay();
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

  /// Call after successful workout to temporarily unlock the app
  void grantTemporaryUnlock(String packageName, {int minutes = 30}) {
    _temporaryUnlocks[packageName] =
        DateTime.now().add(Duration(minutes: minutes));
    _lastUnlockTime = DateTime.now();
    hideBlockOverlay();
    _currentlyBlockedPackage = null;
  }

  /// Grant unlock for the currently blocked package
  void grantCurrentUnlock({int minutes = 30}) {
    if (_currentlyBlockedPackage != null) {
      grantTemporaryUnlock(_currentlyBlockedPackage!, minutes: minutes);
    } else {
      hideBlockOverlay();
    }
  }

  String? get currentlyBlockedPackage => _currentlyBlockedPackage;

  DateTime? get lastUnlockTime => _lastUnlockTime;

  void dispose() {
    stopListening();
  }
}
