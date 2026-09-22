import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/workout_session.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime time;
  final bool isRead;

  _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
    this.isRead = false,
  });
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<_NotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _buildFromData();
  }

  List<_NotificationItem> _buildFromData() {
    final sessions = HiveService.getAllSessions();
    final progress = HiveService.getProgress();
    final items = <_NotificationItem>[];

    // Streak notification
    if (progress.currentStreak > 0) {
      items.add(
        _NotificationItem(
          title: '${progress.currentStreak}-Day Streak!',
          subtitle: 'Keep the momentum going!',
          icon: Icons.local_fire_department,
          color: AppColors.primaryGreen,
          time: progress.lastWorkoutDate ?? DateTime.now(),
          isRead: false,
        ),
      );
    }

    // Recent completed workouts
    for (final WorkoutSession s in sessions.take(8)) {
      if (s.completedAt != null) {
        items.add(
          _NotificationItem(
            title: 'Screen time unlocked',
            subtitle:
                'You completed ${s.completedReps} ${s.exerciseType}. Great job!',
            icon: Icons.lock_open,
            color: AppColors.primaryGreen,
            time: s.completedAt!,
            isRead: true,
          ),
        );
      } else {
        items.add(
          _NotificationItem(
            title: 'Workout incomplete',
            subtitle:
                'You stopped at ${s.completedReps}/${s.targetReps} ${s.exerciseType}',
            icon: Icons.lock,
            color: AppColors.red,
            time: s.startedAt,
            isRead: true,
          ),
        );
      }
    }

    if (items.isEmpty) {
      items.add(
        _NotificationItem(
          title: 'Welcome to SweatLock',
          subtitle: 'Lock apps and earn screen time with real workouts.',
          icon: Icons.fitness_center,
          color: AppColors.primaryGreen,
          time: DateTime.now(),
          isRead: false,
        ),
      );
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  String _timeLabel(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }

  bool _isToday(DateTime t) {
    final n = DateTime.now();
    return t.year == n.year && t.month == n.month && t.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = _items.where((i) => _isToday(i.time)).toList();
    final earlier = _items.where((i) => !_isToday(i.time)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (today.isNotEmpty) ...[
                    Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.color
                                ?.darken(),
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...today.map(_tile),
                    const SizedBox(height: 20),
                  ],
                  if (earlier.isNotEmpty) ...[
                    Text(
                      'EARLIER',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.color
                                ?.darken(),
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...earlier.map(_tile),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(_NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: !item.isRead
          ? BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 5,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: item.color,
            child: Icon(item.icon, color: Colors.white),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.title.cap,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                _timeLabel(item.time),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.color
                          ?.darken(),
                    ),
              ),
            ],
          ),
          subtitle: Text(
            item.subtitle.capitalize,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.color
                      ?.darken(),
                ),
          ),
        ),
      ),
    );
  }
}
