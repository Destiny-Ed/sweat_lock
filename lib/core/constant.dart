const String appName = 'SweatLock';

// Default values
const int defaultReps = 20;
const String defaultExercise = 'push-ups';
const int emergencyUnlocksPerDay = 1;
const int unlockDurationMinutes = 30;

/// Emergency unlock lasts this many minutes (can differ from normal).
const int emergencyUnlockDurationMinutes = 45;

/// Free usage window before iOS system shield is applied (minutes).
const int iosUsageLimitMinutes = 5;

/// Show local notification this many minutes before the shield.
const int iosWarningBeforeBlockMinutes = 2;

/// How often Flutter re-checks (only while app is alive).
const int iosUsageCheckIntervalMinutes = 1;

/// Unique PDF pages required to unlock instead of a workout.
const int requiredReadingPages = 3;

const List<String> supportedExercises = [
  'push-ups',
  'squats',
  'sit-ups',
  'jumping jacks',
];

const List<String> supportedMusicGenres = [
  'pop',
  'hip hop / rap',
  'rock',
  'electronic / EDM',
  'latin',
  'R&B',
  'indie',
  'gospel',
  'classical / instrumental',
  'afrobeats',
];

const String blockedAppsBox = 'blocked_apps';
const String sessionsBox = 'workout_sessions';
const String progressBox = 'user_progress';
const String settingsBox = 'settings';
