import 'dart:io';

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:uuid/uuid.dart';

class BlockingProvider extends ChangeNotifier {
  List<BlockedApp> _blockedApps = [];
  List<BlockedApp> get blockedApps => _blockedApps;

  List<AppInfo> _installedApps = [];
  List<AppInfo> get installedApps => _installedApps;

  bool _isLoadingApps = false;
  bool get isLoadingApps => _isLoadingApps;

  bool _accessibilityEnabled = false;
  bool get accessibilityEnabled => _accessibilityEnabled;

  BlockingProvider() {
    loadBlockedApps();
    checkAccessibility();
  }

  void loadBlockedApps() {
    _blockedApps = HiveService.getBlockedApps();
    notifyListeners();
  }

  Future<void> checkAccessibility() async {
    if (!Platform.isAndroid) {
      _accessibilityEnabled = false;
      notifyListeners();
      return;
    }
    _accessibilityEnabled =
        await BlockingService.instance.isAccessibilityEnabled();
    notifyListeners();

    if (_accessibilityEnabled) {
      await BlockingService.instance.startListening();
    }
  }

  Future<void> requestAccessibility() async {
    await BlockingService.instance.requestAccessibilityPermission();
    await checkAccessibility();
  }

  Future<void> loadInstalledApps() async {
    if (!Platform.isAndroid) return;
    _isLoadingApps = true;
    notifyListeners();

    try {
      _installedApps = await InstalledApps.getInstalledApps(
        true, // exclude system apps
        true, // with icon
      );
      // Sort alphabetically
      _installedApps.sort(
        (a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
      );
    } catch (e) {
      debugPrint('loadInstalledApps error: $e');
      _installedApps = [];
    }

    _isLoadingApps = false;
    notifyListeners();
  }

  bool isAppBlocked(String packageName) {
    return _blockedApps.any(
      (a) => a.packageName == packageName && a.isActive,
    );
  }

  Future<void> toggleApp({
    required AppInfo app,
    int requiredReps = 20,
    String exerciseType = 'push-ups',
  }) async {
    final packageName = app.packageName ?? '';
    if (packageName.isEmpty) return;

    final existingIndex =
        _blockedApps.indexWhere((a) => a.packageName == packageName);

    if (existingIndex >= 0) {
      // Remove
      await HiveService.removeBlockedApp(_blockedApps[existingIndex].id);
    } else {
      // Add
      final blocked = BlockedApp(
        id: const Uuid().v4(),
        appName: app.name ?? packageName,
        packageName: packageName,
        requiredReps: requiredReps,
        exerciseType: exerciseType,
        isActive: true,
      );
      await HiveService.addBlockedApp(blocked);
    }

    loadBlockedApps();
  }

  Future<void> updateBlockedApp(BlockedApp app) async {
    await HiveService.addBlockedApp(app);
    loadBlockedApps();
  }

  Future<void> removeBlockedApp(String id) async {
    await HiveService.removeBlockedApp(id);
    loadBlockedApps();
  }
}
