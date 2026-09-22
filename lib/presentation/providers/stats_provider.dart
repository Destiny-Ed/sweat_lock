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
        final start = now.subtract(Duration(days: now.weekday - 1));
        final dayStart = DateTime(start.year, start.month, start.day);
        return _sessions.where((s) => s.startedAt.isAfter(dayStart)).toList();
      case 'monthly':
        final start = DateTime(now.year, now.month, 1);
        return _sessions.where((s) => s.startedAt.isAfter(start)).toList();
      default:
        return _sessions;
    }
  }

  int get totalReps =>
      filteredSessions.fold(0, (sum, s) => sum + s.completedReps);

  int get lifetimeReps => HiveService.getProgress().totalReps;

  int get totalWorkouts =>
      filteredSessions.where((s) => s.completedAt != null).length;

  /// Mon–Sun (or last 7 days) rep totals for bar chart
  List<double> get weeklyReps {
    final now = DateTime.now();
    final result = List<double>.filled(7, 0);
    for (final s in _sessions) {
      final diff = now.difference(s.startedAt).inDays;
      if (diff >= 0 && diff < 7) {
        final index = 6 - diff; // oldest left, today right
        if (index >= 0 && index < 7) {
          result[index] += s.completedReps.toDouble();
        }
      }
    }
    return result;
  }

  /// Most expensive app by total reps unlocked
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
