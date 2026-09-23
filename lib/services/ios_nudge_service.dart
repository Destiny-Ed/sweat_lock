import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';

/// iOS blocking via **ManagedSettings** system shields.
///
/// Why Flutter-only timers failed: iOS suspends the app while you use TikTok,
/// so Dart timers never fire. Native UNUserNotificationCenter schedules
/// survive in the background; ManagedSettings shields block apps system-wide
/// without SweatLock being open.
class IosNudgeService {
  static IosNudgeService? _instance;
  static IosNudgeService get instance => _instance ??= IosNudgeService._();

  IosNudgeService._();

  static const _channel = MethodChannel('sweatlock/screen_time');

  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  List<Map<String, dynamic>> _selectedIosApps = [];
  List<Map<String, dynamic>> get selectedIosApps =>
      List.unmodifiable(_selectedIosApps);

  void Function(String bundleId, int minutes)? _onNudgeNeeded;

  void setNudgeCallback(void Function(String bundleId, int minutes)? cb) {
    _onNudgeNeeded = cb;
  }

  void loadSavedSelections() {
    try {
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

  Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } catch (e) {
      debugPrint('requestAuthorization error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> selectApps() async {
    if (!Platform.isIOS) return [];
    try {
      final result = await _channel.invokeMethod<List>('selectApps');
      if (result == null) return [];

      final apps =
          result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _selectedIosApps = apps;

      final existing = HiveService.getBlockedApps()
          .where((a) => a.packageName.isNotEmpty && a.bundleId.isEmpty)
          .toList();

      for (final app in apps) {
        final bundleId =
            app['bundleId']?.toString() ?? app['token']?.toString() ?? '';
        final blocked = BlockedApp(
          id: app['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          appName: app['appName']?.toString() ?? 'Selected App',
          packageName: '',
          bundleId: bundleId,
          requiredReps: app['requiredReps'] as int? ?? defaultReps,
          exerciseType: app['exerciseType']?.toString() ?? defaultExercise,
          playlistName: '${app['appName'] ?? 'App'} Workout Mix',
        );
        existing.removeWhere((a) => a.bundleId == bundleId);
        existing.add(blocked);
      }

      await HiveService.saveBlockedApps(existing);

      // Arm native timed lock (notifications + ManagedSettings)
      await startMonitoring();

      return apps;
    } catch (e) {
      debugPrint('selectApps error: $e');
      return [];
    }
  }

  /// Start / restart free window:
  /// - notification at (limit - 2) min
  /// - system shield at limit min
  Future<void> startMonitoring() async {
    if (!Platform.isIOS) return;
    loadSavedSelections();
    _isMonitoring = true;

    try {
      await _channel.invokeMethod('startTimedLock', {
        'warningMinutes': iosWarningBeforeBlockMinutes,
        'lockMinutes': iosUsageLimitMinutes,
      });
      debugPrint(
        'IosNudgeService: timed lock armed '
        '(warn ${iosUsageLimitMinutes - iosWarningBeforeBlockMinutes}m, '
        'lock ${iosUsageLimitMinutes}m)',
      );
    } catch (e) {
      debugPrint('startTimedLock error: $e');
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    try {
      await _channel.invokeMethod('cancelTimedLock');
    } catch (_) {}
  }

  /// Apply system shield now (blocks selected apps even outside SweatLock)
  Future<void> applyShield() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('applyShield');
    } catch (e) {
      debugPrint('applyShield error: $e');
    }
  }

  Future<void> clearShield() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('clearShield');
    } catch (e) {
      debugPrint('clearShield error: $e');
    }
  }

  /// After successful workout:
  /// 1) clear system shield
  /// 2) temporary unlock for [unlockDurationMinutes]
  /// 3) when that ends, shield re-applies natively
  /// 4) restart free-window monitoring for the next cycle
  Future<void> onWorkoutCompleted({int? unlockMinutes}) async {
    if (!Platform.isIOS) return;
    final mins = unlockMinutes ?? unlockDurationMinutes;

    try {
      await _channel.invokeMethod('grantTemporaryUnlock', {
        'minutes': mins,
      });
      // After unlock window, native side re-applies shield.
      // Also restart a fresh free window after unlock for continuous cycle:
      // schedule restart of timed lock after unlock expires.
      Future.delayed(Duration(minutes: mins), () async {
        await startMonitoring();
      });
      debugPrint('IosNudgeService: temporary unlock $mins min, then re-monitor');
    } catch (e) {
      debugPrint('onWorkoutCompleted error: $e');
    }
  }

  /// Explicit restart of free window + notifications (e.g. after workout UI)
  Future<void> restartMonitoringAfterUnlock() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('restartMonitoring', {
        'warningMinutes': iosWarningBeforeBlockMinutes,
        'lockMinutes': iosUsageLimitMinutes,
      });
      _isMonitoring = true;
    } catch (e) {
      debugPrint('restartMonitoring error: $e');
    }
  }

  Future<void> resetUsageForApp(String bundleId) async {
    // Restart full cycle after workout for that session
    await onWorkoutCompleted();
  }

  void triggerManualNudge({String? bundleId}) {
    final id = bundleId ??
        (_selectedIosApps.isNotEmpty
            ? _selectedIosApps.first['bundleId']?.toString() ?? ''
            : '');
    _onNudgeNeeded?.call(id, iosUsageLimitMinutes);
  }

  void dispose() {
    stopMonitoring();
  }
}
