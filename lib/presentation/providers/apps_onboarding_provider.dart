import 'dart:developer';
import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:sweat_lock/data/models/workout_model.dart';
import 'package:sweat_lock/service/services.dart';

class AppsOnboardingProvider extends ChangeNotifier {
  int _currentIndex = 1;
  int get currentIndex => _currentIndex;

  set currentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  int maxIndex = 3;

  ExerciseAppModel? _selectedExerciseAppWorkout;
  ExerciseAppModel? get selectedExerciseAppWorkout =>
      _selectedExerciseAppWorkout;

  set selectedExerciseAppWorkout(ExerciseAppModel appData) {
    _selectedExerciseAppWorkout = appData;
    notifyListeners();
  }

  List<Application> _availableAndroidApps = [];
  List<Application> get availableAndroidApps => _availableAndroidApps;

  set availableAndroidApps(List<Application> appData) {
    _availableAndroidApps = appData;
    notifyListeners();
  }

  ///Use to hold android and iOS selected apps
  final List<AppModel> _selectedBlockedApps = [];
  List<AppModel> get selectedBlockedApps => _selectedBlockedApps;
  void updateSelectedBlockedApps(AppModel appData) {
    if (isAppSelected(appData.packageName)) {
      _selectedBlockedApps.removeWhere(
        (e) => e.packageName.toLowerCase() == appData.packageName.toLowerCase(),
      );
    } else {
      _selectedBlockedApps.add(appData);
    }
    notifyListeners();
  }

  bool isAppSelected(String packageName) => _selectedBlockedApps
      .firstWhere(
        (e) => e.packageName.toLowerCase() == packageName.toLowerCase(),
        orElse: () => AppModel(appName: "", icon: "", packageName: ""),
      )
      .packageName
      .isNotEmpty;

  final List<ExerciseAppModel> _appActivityData = [];
  List<ExerciseAppModel> get appActivityData => _appActivityData;

  List<String> musicGenres = [
    "pop",
    "hip hop / rap",
    "rock",
    "electronic / EDM",
    "latin",
    "R&B",
    "indie",
    "gospel",
    "classical / instrumental",
  ];

  WorkoutModel? _selectedWorkout;
  WorkoutModel? get selectedWorkout => _selectedWorkout;

  set selectedWorkout(WorkoutModel? workout) {
    _selectedWorkout = workout;
    notifyListeners();
  }

  List<WorkoutModel> workouts = [
    WorkoutModel(duration: 20, workout: "push-ups", isReps: true),
    WorkoutModel(duration: 20, workout: "sit-ups", isReps: true),
    WorkoutModel(duration: 20, workout: "squats", isReps: true),
    WorkoutModel(duration: 20, workout: "jumping jacks", isReps: false),
  ];
  final List<String> _selectedGenres = [];
  List<String> get selectedGenres => _selectedGenres;

  set selectedGenres(String value) {
    final lwValue = value.toLowerCase();
    if (_selectedGenres.contains(lwValue)) {
      _selectedGenres.remove(lwValue);
    } else {
      _selectedGenres.add(lwValue);
    }
    notifyListeners();
  }

  void loadAndroidApps() async {
    if (Platform.isIOS) return;
    try {
      _isLoading = true;
      notifyListeners();
      final apps = await AppService.loadAndroidApps();
      _availableAndroidApps = apps;
      notifyListeners();
    } catch (e, s) {
      log("Error fetching android apps : $e", stackTrace: s);
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
