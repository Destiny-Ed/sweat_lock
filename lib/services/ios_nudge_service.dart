import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';

/// iOS soft-nudge system.
/// Hard real-time blocking is not available; we nudge after usage limit.
class IosNudgeService {
  static IosNudgeService? _instance;
  static IosNudgeService get instance => _instance ??= IosNudgeService._();

  IosNudgeService._();

  static const _channel = MethodChannel('sweatlock/screen_time');

  Timer? _usageCheckTimer;
  bool _isMonitoring = false;

  /// Testing default: 3 minutes (see [iosUsageLimitMinutes])
  int usageLimitMinutes = iosUsageLimitMinutes;

  /// Local fallback tracking when native getAppUsage is empty
  final Map<String, DateTime> _localSessionStart = {};
  final Set<String> _nudgedThisSession = {};

  List<Map<String, dynamic>> _selectedIosApps = [];

  bool get isMonitoring => _isMonitoring;
  List<Map<String, dynamic>> get selectedIosApps =>
      List.unmodifiable(_selectedIosApps);

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

      // Start local session clocks for testing fallback
      final now = DateTime.now();
      for (final a in apps) {
        final id = a['bundleId']?.toString() ?? '';
        if (id.isNotEmpty && !_localSessionStart.containsKey(id)) {
          _localSessionStart[id] = now;
        }
      }
    } catch (e) {
      debugPrint('loadSavedSelections error: $e');
    }
  }

  Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('requestAuthorization error: ${e.message}');
      return false;
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

      // Replace iOS-token apps in Hive (keep Android package apps)
      final existing = HiveService.getBlockedApps()
          .where((a) => a.packageName.isNotEmpty && a.bundleId.isEmpty)
          .toList();

      final now = DateTime.now();
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
          playlistName:
              '${app['appName'] ?? 'App'} Workout Mix',
        );
        existing.removeWhere((a) => a.bundleId == bundleId);
        existing.add(blocked);
        if (bundleId.isNotEmpty) {
          _localSessionStart[bundleId] = now;
        }
      }

      await HiveService.saveBlockedApps(existing);
      return apps;
    } on PlatformException catch (e) {
      debugPrint('selectApps error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('selectApps error: $e');
      return [];
    }
  }

  void startMonitoring({int? checkIntervalMinutes}) {
    if (!Platform.isIOS || _isMonitoring) return;
    loadSavedSelections();
    _isMonitoring = true;

    final interval = checkIntervalMinutes ?? iosUsageCheckIntervalMinutes;

    _usageCheckTimer?.cancel();
    _usageCheckTimer = Timer.periodic(
      Duration(minutes: interval),
      (_) => _checkUsageAndNudge(),
    );

    // Also tick every 30s for faster testing feedback
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isMonitoring) _checkUsageAndNudge();
    });

    _checkUsageAndNudge();
    debugPrint(
      'IosNudgeService monitoring started (limit: $usageLimitMinutes min)',
    );
  }

  void stopMonitoring() {
    _usageCheckTimer?.cancel();
    _usageCheckTimer = null;
    _isMonitoring = false;
  }

  Future<void> _checkUsageAndNudge() async {
    if (_selectedIosApps.isEmpty) {
      loadSavedSelections();
      if (_selectedIosApps.isEmpty) return;
    }

    // 1) Try native usage API
    try {
      final usageList = await _channel.invokeMethod<List>('getAppUsage');
      if (usageList != null && usageList.isNotEmpty) {
        for (final item in usageList) {
          final map = Map<String, dynamic>.from(item as Map);
          final minutes = (map['minutes'] as num?)?.toInt() ?? 0;
          final bundleId = map['bundleId']?.toString() ?? '';
          if (minutes >= usageLimitMinutes &&
              !_nudgedThisSession.contains(bundleId)) {
            _nudgedThisSession.add(bundleId);
            _onNudgeNeeded?.call(bundleId, minutes);
            return;
          }
        }
        return;
      }
    } catch (e) {
      debugPrint('getAppUsage unavailable, using local timer: $e');
    }

    // 2) Local fallback timer (for testing when native usage is empty)
    final now = DateTime.now();
    for (final app in _selectedIosApps) {
      final bundleId = app['bundleId']?.toString() ?? '';
      if (bundleId.isEmpty) continue;
      final start = _localSessionStart[bundleId] ?? now;
      final minutes = now.difference(start).inMinutes;
      if (minutes >= usageLimitMinutes &&
          !_nudgedThisSession.contains(bundleId)) {
        _nudgedThisSession.add(bundleId);
        debugPrint(
          'Local nudge for $bundleId after $minutes min (limit $usageLimitMinutes)',
        );
        _onNudgeNeeded?.call(bundleId, minutes);
        return;
      }
    }
  }

  void Function(String bundleId, int minutes)? _onNudgeNeeded;

  void setNudgeCallback(void Function(String bundleId, int minutes)? cb) {
    _onNudgeNeeded = cb;
  }

  void triggerManualNudge({String? bundleId}) {
    final id = bundleId ??
        (_selectedIosApps.isNotEmpty
            ? _selectedIosApps.first['bundleId']?.toString() ?? ''
            : '');
    _onNudgeNeeded?.call(id, usageLimitMinutes);
  }

  Future<void> resetUsageForApp(String bundleId) async {
    _localSessionStart[bundleId] = DateTime.now();
    _nudgedThisSession.remove(bundleId);
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
