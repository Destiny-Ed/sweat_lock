class WorkoutModel {
  final String workout;
  final bool isReps;
  final int duration; // reps count or seconds
  final String? iconName;

  WorkoutModel({
    required this.workout,
    required this.isReps,
    required this.duration,
    this.iconName,
  });

  Map<String, dynamic> toJson() => {
        'workout': workout,
        'isReps': isReps,
        'duration': duration,
        'iconName': iconName,
      };

  factory WorkoutModel.fromJson(Map<String, dynamic> json) => WorkoutModel(
        workout: json['workout'] as String,
        isReps: json['isReps'] as bool,
        duration: json['duration'] as int,
        iconName: json['iconName'] as String?,
      );

  WorkoutModel copyWith({
    String? workout,
    bool? isReps,
    int? duration,
    String? iconName,
  }) {
    return WorkoutModel(
      workout: workout ?? this.workout,
      isReps: isReps ?? this.isReps,
      duration: duration ?? this.duration,
      iconName: iconName ?? this.iconName,
    );
  }
}

class AppModel {
  final String appName;
  final String icon;
  final String packageName;
  final String bundleId;

  AppModel({
    required this.appName,
    required this.icon,
    required this.packageName,
    this.bundleId = '',
  });

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'icon': icon,
        'packageName': packageName,
        'bundleId': bundleId,
      };

  factory AppModel.fromJson(Map<String, dynamic> json) => AppModel(
        appName: json['appName'] as String,
        icon: json['icon'] as String? ?? '',
        packageName: json['packageName'] as String,
        bundleId: json['bundleId'] as String? ?? '',
      );
}

class ExerciseAppModel {
  final List<AppModel> apps;
  final WorkoutModel workout;
  final List<String> genres;

  ExerciseAppModel({
    required this.apps,
    required this.workout,
    required this.genres,
  });

  Map<String, dynamic> toJson() => {
        'apps': apps.map((a) => a.toJson()).toList(),
        'workout': workout.toJson(),
        'genres': genres,
      };

  factory ExerciseAppModel.fromJson(Map<String, dynamic> json) =>
      ExerciseAppModel(
        apps: (json['apps'] as List)
            .map((e) => AppModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        workout: WorkoutModel.fromJson(json['workout'] as Map<String, dynamic>),
        genres: List<String>.from(json['genres'] as List? ?? []),
      );
}
