import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';

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

  String get _displayAppName {
    final apps = HiveService.getBlockedApps()
        .where((a) => a.bundleId.isNotEmpty)
        .toList();
    if (apps.isEmpty) return 'Selected apps';
    if (apps.length == 1) return apps.first.appName;
    return '${apps.first.appName} +${apps.length - 1}';
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

      // Keep Android-only entries; REPLACE all iOS token apps with picker result
      final androidOnly = HiveService.getBlockedApps()
          .where((a) => a.packageName.isNotEmpty && a.bundleId.isEmpty)
          .toList();

      final iosApps = <BlockedApp>[];
      for (final app in apps) {
        final bundleId =
            app['bundleId']?.toString() ?? app['token']?.toString() ?? '';
        if (bundleId.isEmpty) continue;
        final name = app['appName']?.toString() ?? 'App';
        iosApps.add(
          BlockedApp(
            id: app['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            appName: name,
            packageName: '',
            bundleId: bundleId,
            requiredReps: app['requiredReps'] as int? ?? defaultReps,
            exerciseType: app['exerciseType']?.toString() ?? defaultExercise,
            playlistName: '$name Workout Mix',
          ),
        );
      }

      await HiveService.saveBlockedApps([...androidOnly, ...iosApps]);

      // Empty picker → unlock; otherwise apply mode
      if (iosApps.isEmpty) {
        await clearShield();
        await stopMonitoring();
      } else {
        await startMonitoring();
      }

      return apps;
    } catch (e) {
      debugPrint('selectApps error: $e');
      return [];
    }
  }

  Future<void> startMonitoring() async {
    if (!Platform.isIOS) return;
    loadSavedSelections();
    _isMonitoring = true;

    final mode = HiveService.getBlockMode();
    final lock = HiveService.getFreeMinutes();
    final warning = HiveService.getWarningMinutes();

    try {
      // Prefer setBlockMode so native always clears then applies correctly
      await _channel.invokeMethod('setBlockMode', {
        'warningMinutes': warning,
        'lockMinutes': lock,
        'mode': mode,
        'appName': _displayAppName,
      });
      debugPrint(
        'IosNudgeService: setBlockMode=$mode lock=${lock}m warn=${warning}m',
      );
    } catch (e) {
      debugPrint('setBlockMode error: $e');
      try {
        await _channel.invokeMethod('startTimedLock', {
          'warningMinutes': warning,
          'lockMinutes': lock,
          'mode': mode,
          'appName': _displayAppName,
        });
      } catch (e2) {
        debugPrint('startTimedLock error: $e2');
      }
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    try {
      await _channel.invokeMethod('cancelTimedLock');
    } catch (_) {}
  }

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

  Future<void> onWorkoutCompleted({int? unlockMinutes}) async {
    if (!Platform.isIOS) return;
    final mins = unlockMinutes ?? HiveService.getUnlockDurationMinutes();

    try {
      await _channel.invokeMethod('grantTemporaryUnlock', {'minutes': mins});
      Future.delayed(Duration(minutes: mins), () async {
        await startMonitoring();
      });
    } catch (e) {
      debugPrint('onWorkoutCompleted error: $e');
    }
  }

  Future<void> restartMonitoringAfterUnlock() async {
    await startMonitoring();
  }

  Future<void> resetUsageForApp(String bundleId) async {
    await onWorkoutCompleted();
  }

  void triggerManualNudge({String? bundleId}) {
    final id = bundleId ??
        (_selectedIosApps.isNotEmpty
            ? _selectedIosApps.first['bundleId']?.toString() ?? ''
            : '');
    _onNudgeNeeded?.call(id, HiveService.getFreeMinutes());
  }

  void dispose() {
    stopMonitoring();
  }
}
