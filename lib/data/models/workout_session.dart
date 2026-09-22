class WorkoutSession {
  final String id;
  final String exerciseType;
  final int targetReps;
  final int completedReps;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? unlockedAppId;
  final bool wasEmergencyUnlock;

  WorkoutSession({
    required this.id,
    required this.exerciseType,
    required this.targetReps,
    required this.completedReps,
    required this.startedAt,
    this.completedAt,
    this.unlockedAppId,
    this.wasEmergencyUnlock = false,
  });

  bool get isCompleted => completedAt != null && completedReps >= targetReps;

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseType': exerciseType,
        'targetReps': targetReps,
        'completedReps': completedReps,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'unlockedAppId': unlockedAppId,
        'wasEmergencyUnlock': wasEmergencyUnlock,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        exerciseType: json['exerciseType'] as String,
        targetReps: json['targetReps'] as int,
        completedReps: json['completedReps'] as int,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        unlockedAppId: json['unlockedAppId'] as String?,
        wasEmergencyUnlock: json['wasEmergencyUnlock'] as bool? ?? false,
      );
}
