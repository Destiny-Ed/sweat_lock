import 'package:flutter/material.dart';
import 'package:sweat_lock/data/models/workout_model.dart';

class AppsOnboardingProvider extends ChangeNotifier {
  int _currentIndex = 1;
  int get currentIndex => _currentIndex;

  set currentIndex(int value) {
    _currentIndex = value;
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
}
