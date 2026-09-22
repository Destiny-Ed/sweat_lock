const String appName = 'SweatLock';

// Default values
const int defaultReps = 20;
const String defaultExercise = 'push-ups';
const int emergencyUnlocksPerDay = 1;
const int unlockDurationMinutes = 30;

/// iOS soft-nudge usage limit (minutes).
/// Set low for testing — raise for production (e.g. 25).
const int iosUsageLimitMinutes = 3;

/// How often iOS checks usage (minutes)
const int iosUsageCheckIntervalMinutes = 1;

const List<String> supportedExercises = [
  'push-ups',
  'squats',
  'sit-ups',
  'jumping jacks',
];

const String blockedAppsBox = 'blocked_apps';
const String sessionsBox = 'workout_sessions';
const String progressBox = 'user_progress';
const String settingsBox = 'settings';
