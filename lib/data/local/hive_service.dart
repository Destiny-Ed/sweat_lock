import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/data/models/user_progress.dart';
import 'package:sweat_lock/data/models/workout_session.dart';

class HiveService {
  static const String _blockedAppsBox = 'blocked_apps';
  static const String _sessionsBox = 'workout_sessions';
  static const String _progressBox = 'user_progress';
  static const String _settingsBox = 'settings';

  static late Box _blockedApps;
  static late Box _sessions;
  static late Box _progress;
  static late Box _settings;

  static Future<void> init() async {
    await Hive.initFlutter();
    _blockedApps = await Hive.openBox(_blockedAppsBox);
    _sessions = await Hive.openBox(_sessionsBox);
    _progress = await Hive.openBox(_progressBox);
    _settings = await Hive.openBox(_settingsBox);
  }

  // -------------------- Blocked Apps --------------------
  static Future<void> saveBlockedApps(List<BlockedApp> apps) async {
    final data = apps.map((a) => a.toJson()).toList();
    await _blockedApps.put('list', data);
  }

  static List<BlockedApp> getBlockedApps() {
    final raw = _blockedApps.get('list', defaultValue: <dynamic>[]);
    return (raw as List)
        .map((e) => BlockedApp.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> addBlockedApp(BlockedApp app) async {
    final apps = getBlockedApps();
    apps.removeWhere((a) => a.id == app.id);
    apps.add(app);
    await saveBlockedApps(apps);
  }

  static Future<void> removeBlockedApp(String id) async {
    final apps = getBlockedApps();
    apps.removeWhere((a) => a.id == id);
    await saveBlockedApps(apps);
  }

  // -------------------- Workout Sessions --------------------
  static Future<void> saveSession(WorkoutSession session) async {
    await _sessions.put(session.id, session.toJson());
  }

  static List<WorkoutSession> getAllSessions() {
    return _sessions.values
        .map((e) => WorkoutSession.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  static List<WorkoutSession> getSessionsForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return getAllSessions()
        .where((s) =>
            s.startedAt.isAfter(dayStart) && s.startedAt.isBefore(dayEnd))
        .toList();
  }

  // -------------------- User Progress --------------------
  static Future<void> saveProgress(UserProgress progress) async {
    await _progress.put('data', progress.toJson());
  }

  static UserProgress getProgress() {
    final raw = _progress.get('data');
    if (raw == null) return UserProgress();
    return UserProgress.fromJson(Map<String, dynamic>.from(raw));
  }

  // -------------------- Settings --------------------
  static Future<void> setOnboardingComplete(bool value) async {
    await _settings.put('onboarding_complete', value);
  }

  static bool isOnboardingComplete() {
    return _settings.get('onboarding_complete', defaultValue: false) as bool;
  }

  static Future<void> setDefaultReps(int reps) async {
    await _settings.put('default_reps', reps);
  }

  static int getDefaultReps() {
    return _settings.get('default_reps', defaultValue: 20) as int;
  }

  static Future<void> setDefaultExercise(String exercise) async {
    await _settings.put('default_exercise', exercise);
  }

  static String getDefaultExercise() {
    return _settings.get('default_exercise', defaultValue: 'push-ups') as String;
  }

  static Future<void> setMusicGenres(List<String> genres) async {
    await _settings.put('music_genres', genres);
  }

  static List<String> getMusicGenres() {
    final raw = _settings.get('music_genres', defaultValue: <String>[]);
    return List<String>.from(raw);
  }
}
