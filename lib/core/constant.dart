const String appName = 'SweatLock';

// Default values
const int defaultReps = 20;
const String defaultExercise = 'push-ups';
const int emergencyUnlocksPerDay = 1;
const int unlockDurationMinutes = 30; // How long app stays unlocked after workout

// Exercise types
const List<String> supportedExercises = [
  'push-ups',
  'squats',
  'sit-ups',
  'jumping jacks',
];

// Hive box names
const String blockedAppsBox = 'blocked_apps';
const String sessionsBox = 'workout_sessions';
const String progressBox = 'user_progress';
const String settingsBox = 'settings';
