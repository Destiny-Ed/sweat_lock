class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final int totalReps;
  final int totalWorkouts;
  final DateTime? lastWorkoutDate;
  final int emergencyUnlocksUsedToday;
  final DateTime? lastEmergencyUnlockDate;

  UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalReps = 0,
    this.totalWorkouts = 0,
    this.lastWorkoutDate,
    this.emergencyUnlocksUsedToday = 0,
    this.lastEmergencyUnlockDate,
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalReps': totalReps,
        'totalWorkouts': totalWorkouts,
        'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
        'emergencyUnlocksUsedToday': emergencyUnlocksUsedToday,
        'lastEmergencyUnlockDate': lastEmergencyUnlockDate?.toIso8601String(),
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        totalReps: json['totalReps'] as int? ?? 0,
        totalWorkouts: json['totalWorkouts'] as int? ?? 0,
        lastWorkoutDate: json['lastWorkoutDate'] != null
            ? DateTime.parse(json['lastWorkoutDate'] as String)
            : null,
        emergencyUnlocksUsedToday:
            json['emergencyUnlocksUsedToday'] as int? ?? 0,
        lastEmergencyUnlockDate: json['lastEmergencyUnlockDate'] != null
            ? DateTime.parse(json['lastEmergencyUnlockDate'] as String)
            : null,
      );

  UserProgress copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalReps,
    int? totalWorkouts,
    DateTime? lastWorkoutDate,
    int? emergencyUnlocksUsedToday,
    DateTime? lastEmergencyUnlockDate,
  }) {
    return UserProgress(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalReps: totalReps ?? this.totalReps,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      emergencyUnlocksUsedToday:
          emergencyUnlocksUsedToday ?? this.emergencyUnlocksUsedToday,
      lastEmergencyUnlockDate:
          lastEmergencyUnlockDate ?? this.lastEmergencyUnlockDate,
    );
  }
}
