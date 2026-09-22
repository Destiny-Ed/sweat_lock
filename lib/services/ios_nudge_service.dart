import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';

/// iOS soft-nudge system.
/// Apple does not allow hard real-time app blocking without special entitlements.
/// This service tracks selected apps and triggers a workout prompt after usage limits.
class IosNudgeService {
  static IosNudgeService? _instance;
  static IosNudgeService get instance => _instance ??= IosNudgeService._();

  IosNudgeService._();

  static const _channel = MethodChannel('sweatlock/screen_time');

  Timer? _usageCheckTimer;
  bool _isMonitoring = false;

  /// Minutes of usage before nudge (default 25)
  int usageLimitMinutes = 25;

  /// Apps currently selected for monitoring (bundle IDs / tokens stored as maps)
  List<Map<String, dynamic>> _selectedIosApps = [];

  bool get isMonitoring => _isMonitoring;

  List<Map<String, dynamic>> get selectedIosApps => List.unmodifiable(_selectedIosApps);

  /// Load previously saved iOS selections from Hive settings
  void loadSavedSelections() {
    try {
      // Reuse settings box via HiveService helpers if needed later
      final apps = HiveService.getBlockedApps()
          .where((a) => a.bundleId.isNotEmpty)
          .map((a) => {
                'id': a.id,
                'appName': a.appName,
                'bundleId': a.bundleId,
                'requiredReps': a.requiredReps,
                'exerciseType': a.exerciseType,
              })
          .toList();
      _selectedIosApps = apps;
    } catch (e) {
      debugPrint('loadSavedSelections error: $e');
    }
  }

  /// Request Screen Time / Family Controls authorization (iOS 15+)
  Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } on PlatformException catch (e) {
      log('requestAuthorization error: ${e.message}');
      return false;
    } catch (e) {
      log('requestAuthorization error: $e');
      return false;
    }
  }

  

  /// Present FamilyActivityPicker and return selected app tokens/info
  Future<List<Map<String, dynamic>>> selectApps() async {
    if (!Platform.isIOS) return [];
    try {
      final result = await _channel.invokeMethod<List>('selectApps');
      if (result == null) return [];

      final apps = result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _selectedIosApps = apps;

      // Persist as BlockedApp entries with bundleId
      for (final app in apps) {
        final blocked = BlockedApp(
          id: app['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          appName: app['appName']?.toString() ?? 'Selected App',
          packageName: '',
          bundleId: app['bundleId']?.toString() ?? app['token']?.toString() ?? '',
          requiredReps: app['requiredReps'] as int? ?? defaultReps,
          exerciseType: app['exerciseType']?.toString() ?? defaultExercise,
        );
        await HiveService.addBlockedApp(blocked);
      }

      return apps;
    } on PlatformException catch (e) {
      debugPrint('selectApps error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('selectApps error: $e');
      return [];
    }
  }

  /// Start periodic usage checks (soft monitoring)
  void startMonitoring({int checkIntervalMinutes = 5}) {
    if (!Platform.isIOS || _isMonitoring) return;
    loadSavedSelections();
    _isMonitoring = true;

    _usageCheckTimer?.cancel();
    _usageCheckTimer = Timer.periodic(
      Duration(minutes: checkIntervalMinutes),
      (_) => _checkUsageAndNudge(),
    );

    // Also check once immediately
    _checkUsageAndNudge();
    debugPrint('IosNudgeService monitoring started');
  }

  void stopMonitoring() {
    _usageCheckTimer?.cancel();
    _usageCheckTimer = null;
    _isMonitoring = false;
  }

  /// Query native side for approximate usage of monitored apps
  Future<void> _checkUsageAndNudge() async {
    if (_selectedIosApps.isEmpty) return;

    try {
      final usageList = await _channel.invokeMethod<List>('getAppUsage');
      if (usageList == null) return;

      for (final item in usageList) {
        final map = Map<String, dynamic>.from(item as Map);
        final minutes = (map['minutes'] as num?)?.toInt() ?? 0;
        final bundleId = map['bundleId']?.toString() ?? '';

        if (minutes >= usageLimitMinutes) {
          // Signal that a nudge should be shown
          // UI layer listens via a simple callback or stream
          _onNudgeNeeded?.call(bundleId, minutes);
          break;
        }
      }
    } on PlatformException catch (e) {
      // Native not implemented yet — fall back to manual nudge trigger
      debugPrint('getAppUsage not available: ${e.message}');
    } catch (e) {
      debugPrint('_checkUsageAndNudge error: $e');
    }
  }

  /// Callback when usage limit is reached
  void Function(String bundleId, int minutes)? _onNudgeNeeded;

  void setNudgeCallback(void Function(String bundleId, int minutes)? cb) {
    _onNudgeNeeded = cb;
  }

  /// Manual trigger (useful for testing and when native usage API is limited)
  void triggerManualNudge({String? bundleId}) {
    final id = bundleId ??
        (_selectedIosApps.isNotEmpty
            ? _selectedIosApps.first['bundleId']?.toString() ?? ''
            : '');
    _onNudgeNeeded?.call(id, usageLimitMinutes);
  }

  /// After workout completed — reset local usage window for that app
  Future<void> resetUsageForApp(String bundleId) async {
    try {
      await _channel.invokeMethod('resetUsage', {'bundleId': bundleId});
    } catch (e) {
      debugPrint('resetUsage error: $e');
    }
  }

  void dispose() {
    stopMonitoring();
  }
}
