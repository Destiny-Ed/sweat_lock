import 'package:flutter/material.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/workout_session.dart';

class StatsProvider extends ChangeNotifier {
  List<String> statTab = ['weekly', 'monthly', 'all time'];

  String _selectedTab = 'weekly';
  String get selectedTab => _selectedTab;

  set selectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  List<WorkoutSession> get _sessions => HiveService.getAllSessions();

  List<WorkoutSession> get filteredSessions {
    final now = DateTime.now();
    switch (_selectedTab) {
      case 'weekly':
        // Calendar week Mon–Sun
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final dayStart = DateTime(monday.year, monday.month, monday.day);
        return _sessions.where((s) => !s.startedAt.isBefore(dayStart)).toList();
      case 'monthly':
        final start = DateTime(now.year, now.month, 1);
        return _sessions.where((s) => !s.startedAt.isBefore(start)).toList();
      default:
        return _sessions;
    }
  }

  int get totalReps =>
      filteredSessions.fold(0, (sum, s) => sum + s.completedReps);

  int get lifetimeReps => HiveService.getProgress().totalReps;

  int get totalWorkouts =>
      filteredSessions.where((s) => s.completedAt != null).length;

  /// Mon=0 … Sun=6 for the **current calendar week** (matches axis labels).
  List<double> get weeklyReps {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final result = List<double>.filled(7, 0);

    for (final s in _sessions) {
      final day = DateTime(
        s.startedAt.year,
        s.startedAt.month,
        s.startedAt.day,
      );
      final diff = day.difference(monday).inDays;
      if (diff >= 0 && diff < 7) {
        result[diff] += s.completedReps.toDouble();
      }
    }
    return result;
  }

  /// Labels Mon–Sun for the current week (index matches [weeklyReps]).
  List<String> get weeklyLabels =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  int get todayIndex => DateTime.now().weekday - 1; // Mon=0

  MapEntry<String, int>? get topAppByReps {
    final map = <String, int>{};
    for (final s in filteredSessions) {
      if (s.unlockedAppId == null) continue;
      final apps = HiveService.getBlockedApps();
      final match = apps.cast<dynamic>().firstWhere(
            (a) => a.id == s.unlockedAppId,
            orElse: () => null,
          );
      final name = match?.appName ?? 'Unknown';
      map[name] = (map[name] ?? 0) + s.completedReps;
    }
    if (map.isEmpty) return null;
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first;
  }

  void refresh() => notifyListeners();
}
