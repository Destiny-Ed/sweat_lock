import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/data/models/workout_model.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';
import 'package:uuid/uuid.dart';

class AppsOnboardingProvider extends ChangeNotifier {
  int _currentIndex = 1;
  int get currentIndex => _currentIndex;
  set currentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  int maxIndex = 3;

  // ---------- Android installed apps ----------
  List<AppInfo> _installedApps = [];
  List<AppInfo> get installedApps => _installedApps;
  bool _loadingInstalled = false;
  bool get loadingInstalled => _loadingInstalled;

  Future<void> loadInstalledApps() async {
    if (!Platform.isAndroid) return;
    _loadingInstalled = true;
    notifyListeners();
    try {
      _installedApps = await InstalledApps.getInstalledApps(true, true);
      _installedApps.sort(
        (a, b) =>
            (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
      );
    } catch (e) {
      debugPrint('loadInstalledApps error: $e');
      _installedApps = [];
    }
    _loadingInstalled = false;
    notifyListeners();
  }

  // ---------- Selection (key = packageName OR bundleId) ----------
  final Map<String, BlockedApp> _appConfigs = {};
  Map<String, BlockedApp> get appConfigs => Map.unmodifiable(_appConfigs);
  List<BlockedApp> get selectedBlockedApps => _appConfigs.values.toList();

  bool isKeySelected(String key) => _appConfigs.containsKey(key);

  void toggleInstalledApp(AppInfo app) {
    final packageName = app.packageName ?? '';
    if (packageName.isEmpty) return;

    if (_appConfigs.containsKey(packageName)) {
      _appConfigs.remove(packageName);
    } else {
      final name = app.name ?? packageName;
      _appConfigs[packageName] = BlockedApp(
        id: const Uuid().v4(),
        appName: name,
        packageName: packageName,
        requiredReps: defaultReps,
        exerciseType: defaultExercise,
        playlistName: _dummyPlaylistFor(name),
        playlistUrl: _dummyPlaylistUrlFor(name),
        musicGenres: List.from(_selectedGenres),
      );
    }
    notifyListeners();
  }

  bool _iosSelecting = false;
  bool get iosSelecting => _iosSelecting;

  /// iOS: open FamilyActivityPicker and merge into selection
  Future<void> pickIosApps() async {
    if (!Platform.isIOS) return;
    _iosSelecting = true;
    notifyListeners();

    final authorized = await IosNudgeService.instance.requestAuthorization();
    if (authorized) {
      _iosSelecting = false;
      notifyListeners();
      return;
    }

    final apps = await IosNudgeService.instance.selectApps();
    for (final app in apps) {
      final key =
          app['bundleId']?.toString() ?? app['token']?.toString() ?? '';
      if (key.isEmpty) continue;
      final name = app['appName']?.toString() ?? 'Selected App';
      _appConfigs[key] = BlockedApp(
        id: app['id']?.toString() ?? const Uuid().v4(),
        appName: name,
        packageName: '',
        bundleId: key,
        requiredReps: app['requiredReps'] as int? ?? defaultReps,
        exerciseType: app['exerciseType']?.toString() ?? defaultExercise,
        playlistName: _dummyPlaylistFor(name),
        playlistUrl: _dummyPlaylistUrlFor(name),
        musicGenres: List.from(_selectedGenres),
      );
    }

    _iosSelecting = false;
    notifyListeners();
  }

  void removeSelected(String key) {
    _appConfigs.remove(key);
    notifyListeners();
  }

  void setAppExercise(String key, String exerciseType) {
    final current = _appConfigs[key];
    if (current == null) return;
    _appConfigs[key] = current.copyWith(exerciseType: exerciseType);
    notifyListeners();
  }

  void setAppReps(String key, int reps) {
    final current = _appConfigs[key];
    if (current == null) return;
    _appConfigs[key] = current.copyWith(requiredReps: reps.clamp(5, 100));
    notifyListeners();
  }

  void incrementReps(String key) {
    final current = _appConfigs[key];
    if (current == null) return;
    setAppReps(key, current.requiredReps + 5);
  }

  void decrementReps(String key) {
    final current = _appConfigs[key];
    if (current == null) return;
    setAppReps(key, current.requiredReps - 5);
  }

  String configKey(BlockedApp app) =>
      app.packageName.isNotEmpty ? app.packageName : app.bundleId;

  void applyGenresToApps() {
    for (final key in _appConfigs.keys.toList()) {
      final app = _appConfigs[key]!;
      _appConfigs[key] = app.copyWith(
        musicGenres: List.from(_selectedGenres),
        playlistName: _selectedGenres.isEmpty
            ? app.playlistName
            : '${_selectedGenres.first} Mix · ${app.appName}',
        playlistUrl: _dummyPlaylistUrlFor(
          _selectedGenres.isEmpty ? app.appName : _selectedGenres.first,
        ),
      );
    }
    notifyListeners();
  }

  List<String> musicGenres = [
    'pop',
    'hip hop / rap',
    'rock',
    'electronic / EDM',
    'latin',
    'R&B',
    'indie',
    'gospel',
    'classical / instrumental',
  ];

  final List<String> _selectedGenres = [];
  List<String> get selectedGenres => List.unmodifiable(_selectedGenres);

  void toggleGenre(String value) {
    final lw = value.toLowerCase();
    if (_selectedGenres.contains(lw)) {
      _selectedGenres.remove(lw);
    } else {
      _selectedGenres.add(lw);
    }
    notifyListeners();
  }

  set selectedGenres(String value) => toggleGenre(value);

  List<WorkoutModel> workouts = [
    WorkoutModel(duration: 20, workout: 'push-ups', isReps: true),
    WorkoutModel(duration: 20, workout: 'sit-ups', isReps: true),
    WorkoutModel(duration: 20, workout: 'squats', isReps: true),
    WorkoutModel(duration: 20, workout: 'jumping jacks', isReps: true),
  ];

  String _dummyPlaylistFor(String seed) => '$seed Workout Mix';

  String _dummyPlaylistUrlFor(String seed) {
    final map = {
      'pop': 'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M',
      'hip hop / rap':
          'https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd',
      'rock': 'https://open.spotify.com/playlist/37i9dQZF1DWXRqgorJj26U',
      'electronic / edm':
          'https://open.spotify.com/playlist/37i9dQZF1DX4dyzvuaRJ0n',
      'gospel': 'https://open.spotify.com/playlist/37i9dQZF1DX7OIddoGCStJ',
    };
    return map[seed.toLowerCase()] ??
        'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfWWJh';
  }

  Uint8List? iconForPackage(String packageName) {
    try {
      final app = _installedApps.firstWhere(
        (a) => a.packageName == packageName,
      );
      return app.icon;
    } catch (_) {
      return null;
    }
  }

  String? validateStep(int step) {
    switch (step) {
      case 1:
        if (_appConfigs.isEmpty) return 'Select at least one app to lock';
        return null;
      case 2:
        return null;
      case 3:
        if (_appConfigs.isEmpty) return 'No apps configured';
        return null;
      default:
        return null;
    }
  }

  Future<void> saveToHive() async {
    applyGenresToApps();
    final apps = selectedBlockedApps;
    await HiveService.saveBlockedApps(apps);
    await HiveService.setMusicGenres(_selectedGenres);
    if (apps.isNotEmpty) {
      await HiveService.setDefaultReps(apps.first.requiredReps);
      await HiveService.setDefaultExercise(apps.first.exerciseType);
    }
    await HiveService.setOnboardingComplete(true);
  }
}
