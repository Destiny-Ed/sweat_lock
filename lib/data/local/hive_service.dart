import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/data/models/focus_schedule.dart';
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

  static Future<void> saveProgress(UserProgress progress) async {
    await _progress.put('data', progress.toJson());
  }

  static UserProgress getProgress() {
    final raw = _progress.get('data');
    if (raw == null) return UserProgress();
    return UserProgress.fromJson(Map<String, dynamic>.from(raw));
  }

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

  static Future<void> setStepGoal(int steps) async {
    await _settings.put('step_goal', steps.clamp(100, 20000));
  }

  static int getStepGoal() {
    return _settings.get('step_goal', defaultValue: defaultStepGoal) as int;
  }

  static Future<void> setStepsUnlockEnabled(bool value) async {
    await _settings.put('steps_unlock_enabled', value);
  }

  static bool getStepsUnlockEnabled() {
    return _settings.get('steps_unlock_enabled', defaultValue: true) as bool;
  }

  static Future<void> setMusicGenres(List<String> genres) async {
    await _settings.put('music_genres', genres);
  }

  static List<String> getMusicGenres() {
    final raw = _settings.get('music_genres', defaultValue: <String>[]);
    return List<String>.from(raw);
  }

  static Future<void> setPreferYoutubeMusic(bool value) async {
    await _settings.put('prefer_youtube_music', value);
  }

  static bool getPreferYoutubeMusic() {
    return _settings.get('prefer_youtube_music', defaultValue: false) as bool;
  }

  static Future<void> setBlockMode(String mode) async {
    await _settings.put('block_mode', mode);
  }

  static String getBlockMode() {
    return _settings.get('block_mode', defaultValue: 'timed') as String;
  }

  static Future<void> setFreeMinutes(int minutes) async {
    await _settings.put('free_minutes', minutes.clamp(1, 120));
  }

  static int getFreeMinutes() {
    return _settings.get('free_minutes', defaultValue: iosUsageLimitMinutes)
        as int;
  }

  static Future<void> setWarningMinutes(int minutes) async {
    await _settings.put('warning_minutes', minutes.clamp(1, 30));
  }

  static int getWarningMinutes() {
    return _settings.get(
      'warning_minutes',
      defaultValue: iosWarningBeforeBlockMinutes,
    ) as int;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _settings.put('notifications_enabled', value);
  }

  static bool getNotificationsEnabled() {
    return _settings.get('notifications_enabled', defaultValue: true) as bool;
  }

  static Future<void> setPreventUninstall(bool value) async {
    await _settings.put('prevent_uninstall', value);
  }

  static bool getPreventUninstall() {
    return _settings.get('prevent_uninstall', defaultValue: false) as bool;
  }

  static Future<void> setUnlockDurationMinutes(int minutes) async {
    await _settings.put('unlock_duration', minutes.clamp(5, 180));
  }

  static int getUnlockDurationMinutes() {
    return _settings.get(
      'unlock_duration',
      defaultValue: unlockDurationMinutes,
    ) as int;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final s = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settings.put('theme_mode', s);
  }

  static ThemeMode getThemeMode() {
    final s = _settings.get('theme_mode', defaultValue: 'system') as String;
    return switch (s) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setReadingPdfPath(String? path) async {
    if (path == null || path.isEmpty) {
      await _settings.delete('reading_pdf_path');
    } else {
      await _settings.put('reading_pdf_path', path);
    }
  }

  static String? getReadingPdfPath() {
    return _settings.get('reading_pdf_path') as String?;
  }

  static Future<void> setReadingUnlockEnabled(bool value) async {
    await _settings.put('reading_unlock_enabled', value);
  }

  static bool getReadingUnlockEnabled() {
    return _settings.get('reading_unlock_enabled', defaultValue: true) as bool;
  }

  // ---- Focus schedule ----
  static Future<void> setFocusSchedule(FocusSchedule schedule) async {
    await _settings.put('focus_schedule', schedule.toJson());
  }

  static FocusSchedule getFocusSchedule() {
    final raw = _settings.get('focus_schedule');
    if (raw == null) return const FocusSchedule();
    return FocusSchedule.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  // ---- Accountability (local scaffold) ----
  static String getOrCreatePartnerCode() {
    final existing = _settings.get('partner_code') as String?;
    if (existing != null && existing.isNotEmpty) return existing;
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    final code = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    _settings.put('partner_code', code);
    return code;
  }

  static String? getPartnerCode() => _settings.get('partner_code') as String?;

  static Future<void> setLinkedPartnerCode(String? code) async {
    if (code == null || code.isEmpty) {
      await _settings.delete('linked_partner_code');
    } else {
      await _settings.put('linked_partner_code', code.toUpperCase());
    }
  }

  static String? getLinkedPartnerCode() =>
      _settings.get('linked_partner_code') as String?;

  static Future<void> setPackageUnlockUntil(
      String package, DateTime until) async {
    await _settings.put('unlock_until_$package', until.millisecondsSinceEpoch);
  }

  static DateTime? getPackageUnlockUntil(String package) {
    final v = _settings.get('unlock_until_$package');
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v as int);
  }

  static Future<void> clearPackageUnlock(String package) async {
    await _settings.delete('unlock_until_$package');
  }

  static bool isPackageTemporarilyUnlocked(String package) {
    final until = getPackageUnlockUntil(package);
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  static int getUsageMs(String package) {
    return _settings.get('usage_ms_$package', defaultValue: 0) as int;
  }

  static Future<void> setUsageMs(String package, int ms) async {
    await _settings.put('usage_ms_$package', ms < 0 ? 0 : ms);
  }

  static int? getSessionStartMs(String package) {
    return _settings.get('session_start_$package') as int?;
  }

  static Future<void> setSessionStartMs(String package, int? ms) async {
    if (ms == null) {
      await _settings.delete('session_start_$package');
    } else {
      await _settings.put('session_start_$package', ms);
    }
  }

  static bool wasWarned(String package) {
    return _settings.get('warned_$package', defaultValue: false) as bool;
  }

  static Future<void> setWarned(String package, bool value) async {
    await _settings.put('warned_$package', value);
  }

  static int liveUsageMs(String package) {
    var total = getUsageMs(package);
    final start = getSessionStartMs(package);
    if (start != null) {
      total += DateTime.now().millisecondsSinceEpoch - start;
    }
    return total;
  }

  static Future<void> resetPackageUsage(String package) async {
    await _settings.delete('usage_ms_$package');
    await _settings.delete('session_start_$package');
    await _settings.delete('warned_$package');
  }

  static Future<void> setLastBlockedPackage(String? package) async {
    if (package == null || package.isEmpty) {
      await _settings.delete('last_blocked_package');
    } else {
      await _settings.put('last_blocked_package', package);
    }
  }

  static String? getLastBlockedPackage() {
    return _settings.get('last_blocked_package') as String?;
  }

  static Future<void> setLastBlockedAppId(String? id) async {
    if (id == null || id.isEmpty) {
      await _settings.delete('last_blocked_app_id');
    } else {
      await _settings.put('last_blocked_app_id', id);
    }
  }

  static String? getLastBlockedAppId() {
    return _settings.get('last_blocked_app_id') as String?;
  }

  static int emergencyUnlocksRemaining() {
    final progress = getProgress();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int used = progress.emergencyUnlocksUsedToday;
    if (progress.lastEmergencyUnlockDate != null) {
      final last = DateTime(
        progress.lastEmergencyUnlockDate!.year,
        progress.lastEmergencyUnlockDate!.month,
        progress.lastEmergencyUnlockDate!.day,
      );
      if (last != today) used = 0;
    }
    return (emergencyUnlocksPerDay - used).clamp(0, emergencyUnlocksPerDay);
  }

  static Future<void> logout() async {
    await _settings.put('onboarding_complete', false);
    await _blockedApps.clear();
    await _sessions.clear();
    await _progress.clear();
    await _settings.delete('reading_pdf_path');
    await _settings.delete('last_blocked_package');
    await _settings.delete('last_blocked_app_id');
  }
}
