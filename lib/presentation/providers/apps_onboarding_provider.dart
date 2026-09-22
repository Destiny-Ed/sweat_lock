import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/data/models/workout_model.dart';
import 'package:uuid/uuid.dart';

class AppsOnboardingProvider extends ChangeNotifier {
  int _currentIndex = 1;
  int get currentIndex => _currentIndex;

  set currentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  int maxIndex = 3;

  /// Suggested apps for step 1 (empty selection by default)
  final List<SuggestedApp> suggestedApps = const [
    SuggestedApp(name: 'TikTok', packageName: 'com.zhiliaoapp.musically'),
    SuggestedApp(name: 'Instagram', packageName: 'com.instagram.android'),
    SuggestedApp(name: 'YouTube', packageName: 'com.google.android.youtube'),
    SuggestedApp(name: 'X / Twitter', packageName: 'com.twitter.android'),
    SuggestedApp(name: 'Facebook', packageName: 'com.facebook.katana'),
    SuggestedApp(name: 'Snapchat', packageName: 'com.snapchat.android'),
    SuggestedApp(name: 'WhatsApp', packageName: 'com.whatsapp'),
    SuggestedApp(name: 'Reddit', packageName: 'com.reddit.frontpage'),
    SuggestedApp(name: 'Netflix', packageName: 'com.netflix.mediaclient'),
    SuggestedApp(name: 'Chrome', packageName: 'com.android.chrome'),
  ];

  /// Selected package names in step 1
  final Set<String> _selectedPackages = {};
  Set<String> get selectedPackages => _selectedPackages;

  void toggleSuggestedApp(SuggestedApp app) {
    if (_selectedPackages.contains(app.packageName)) {
      _selectedPackages.remove(app.packageName);
      _appConfigs.remove(app.packageName);
    } else {
      _selectedPackages.add(app.packageName);
      _appConfigs[app.packageName] = BlockedApp(
        id: const Uuid().v4(),
        appName: app.name,
        packageName: app.packageName,
        requiredReps: defaultReps,
        exerciseType: defaultExercise,
        playlistName: _dummyPlaylistFor(app.name),
        playlistUrl: _dummyPlaylistUrlFor(app.name),
        musicGenres: List.from(_selectedGenres),
      );
    }
    notifyListeners();
  }

  bool isSuggestedSelected(SuggestedApp app) =>
      _selectedPackages.contains(app.packageName);

  /// Per-app config built during onboarding (packageName -> BlockedApp)
  final Map<String, BlockedApp> _appConfigs = {};
  Map<String, BlockedApp> get appConfigs => Map.unmodifiable(_appConfigs);

  List<BlockedApp> get selectedBlockedApps =>
      _selectedPackages.map((p) => _appConfigs[p]!).toList();

  void setAppExercise(String packageName, String exerciseType) {
    final current = _appConfigs[packageName];
    if (current == null) return;
    _appConfigs[packageName] = current.copyWith(exerciseType: exerciseType);
    notifyListeners();
  }

  void setAppReps(String packageName, int reps) {
    final current = _appConfigs[packageName];
    if (current == null) return;
    final clamped = reps.clamp(5, 100);
    _appConfigs[packageName] = current.copyWith(requiredReps: clamped);
    notifyListeners();
  }

  void incrementReps(String packageName) {
    final current = _appConfigs[packageName];
    if (current == null) return;
    setAppReps(packageName, current.requiredReps + 5);
  }

  void decrementReps(String packageName) {
    final current = _appConfigs[packageName];
    if (current == null) return;
    setAppReps(packageName, current.requiredReps - 5);
  }

  /// Apply selected genres to all currently selected apps' playlists
  void applyGenresToApps() {
    for (final key in _appConfigs.keys.toList()) {
      final app = _appConfigs[key]!;
      _appConfigs[key] = app.copyWith(
        musicGenres: List.from(_selectedGenres),
        playlistName: _selectedGenres.isEmpty
            ? app.playlistName
            : '${_selectedGenres.first} Mix · ${app.appName}',
        playlistUrl: _dummyPlaylistUrlFor(_selectedGenres.isEmpty
            ? app.appName
            : _selectedGenres.first),
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

  // Backward-compatible setter used by older UI
  set selectedGenres(String value) => toggleGenre(value);

  List<WorkoutModel> workouts = [
    WorkoutModel(duration: 20, workout: 'push-ups', isReps: true),
    WorkoutModel(duration: 20, workout: 'sit-ups', isReps: true),
    WorkoutModel(duration: 20, workout: 'squats', isReps: true),
    WorkoutModel(duration: 20, workout: 'jumping jacks', isReps: true),
  ];

  String _dummyPlaylistFor(String seed) => '$seed Workout Mix';

  String _dummyPlaylistUrlFor(String seed) {
    // Dummy Spotify playlist links by genre/app seed
    final map = {
      'pop': 'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M',
      'hip hop / rap': 'https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd',
      'rock': 'https://open.spotify.com/playlist/37i9dQZF1DWXRqgorJj26U',
      'electronic / edm':
          'https://open.spotify.com/playlist/37i9dQZF1DX4dyzvuaRJ0n',
      'gospel': 'https://open.spotify.com/playlist/37i9dQZF1DX7OIddoGCStJ',
    };
    final key = seed.toLowerCase();
    return map[key] ??
        'https://open.spotify.com/playlist/37i9dQZF1DX70RN3TfWWJh';
  }

  String? validateStep(int step) {
    switch (step) {
      case 1:
        if (_selectedPackages.isEmpty) {
          return 'Select at least one app to lock';
        }
        return null;
      case 2:
        // Genres optional — ok to continue
        return null;
      case 3:
        if (_appConfigs.isEmpty) return 'No apps configured';
        return null;
      default:
        return null;
    }
  }

  /// Save everything to Hive and mark onboarding complete
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
