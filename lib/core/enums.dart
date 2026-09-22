enum ExerciseType {
  pushUps,
  squats,
  sitUps,
  jumpingJacks,
}

extension ExerciseTypeX on ExerciseType {
  String get label {
    switch (this) {
      case ExerciseType.pushUps:
        return 'push-ups';
      case ExerciseType.squats:
        return 'squats';
      case ExerciseType.sitUps:
        return 'sit-ups';
      case ExerciseType.jumpingJacks:
        return 'jumping jacks';
    }
  }

  static ExerciseType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'squats':
        return ExerciseType.squats;
      case 'sit-ups':
        return ExerciseType.sitUps;
      case 'jumping jacks':
        return ExerciseType.jumpingJacks;
      case 'push-ups':
      default:
        return ExerciseType.pushUps;
    }
  }
}

enum UnlockReason {
  workoutCompleted,
  emergencyUnlock,
  timerExpired,
}
