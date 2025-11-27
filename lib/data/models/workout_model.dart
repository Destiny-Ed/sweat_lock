class WorkoutModel {
  final String workout;
  final bool isReps;
  final int duration;

  WorkoutModel({
    required this.workout,
    required this.isReps,
    required this.duration,
  });
}

class AppModel {
  final String appName;
  final String icon;
  final String packageName;

  AppModel({
    required this.appName,
    required this.icon,
    required this.packageName,
  });
}

class ExerciseAppModel {
  final List<AppModel> app;
  final WorkoutModel workout;
  final List<String> genres;

  ExerciseAppModel({
    required this.app,
    required this.workout,
    required this.genres,
  });
}
