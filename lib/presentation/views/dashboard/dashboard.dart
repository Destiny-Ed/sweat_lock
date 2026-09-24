import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/views/blocking/select_apps_screen.dart';
import 'package:sweat_lock/presentation/views/dashboard/blocked_apps_details.dart';
import 'package:sweat_lock/presentation/views/notifications/notification.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlockingProvider>().loadBlockedApps();
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatMinutes(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  @override
  Widget build(BuildContext context) {
    final progress = HiveService.getProgress();
    final readingUnlocks = HiveService.getReadingUnlocks();
    final minutesSaved = HiveService.getEstimatedMinutesSaved();
    // Include workout sessions × unlock window as a simple “earned time” proxy
    final earnedFromWorkouts =
        progress.totalWorkouts * HiveService.getUnlockDurationMinutes();
    final totalSaved = minutesSaved + earnedFromWorkouts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 12,
                  ),
            ),
            Text(
              'SweatLock',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<BlockingProvider>(
        builder: (context, blockingVm, _) {
          final blocked = blockingVm.blockedApps;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Streak banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen.withValues(alpha: 0.25),
                              AppColors.primaryGreen.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: AppColors.primaryGreen, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${progress.currentStreak} day streak',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    progress.currentStreak > 0
                                        ? 'Keep earning every open'
                                        : 'Complete a challenge to start',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      16.height(),

                      // Stat grid — simple, not only reps
                      Row(
                        children: [
                          Expanded(
                            child: _statTile(
                              context,
                              icon: Icons.fitness_center_rounded,
                              label: 'Reps',
                              value: '${progress.totalReps}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statTile(
                              context,
                              icon: Icons.menu_book_rounded,
                              label: 'Books read',
                              value: '$readingUnlocks',
                            ),
                          ),
                        ],
                      ),
                      10.height(),
                      Row(
                        children: [
                          Expanded(
                            child: _statTile(
                              context,
                              icon: Icons.schedule_rounded,
                              label: 'Time earned',
                              value: _formatMinutes(totalSaved),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statTile(
                              context,
                              icon: Icons.lock_rounded,
                              label: 'Apps locked',
                              value: '${blocked.length}',
                            ),
                          ),
                        ],
                      ),
                      10.height(),
                      _statTile(
                        context,
                        icon: Icons.repeat_rounded,
                        label: 'Workouts completed',
                        value: '${progress.totalWorkouts}',
                        wide: true,
                      ),

                      28.height(),
                      Text(
                        'Locked apps',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      12.height(),

                      if (blocked.any((a) => a.bundleId.isNotEmpty))
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: UiKitView(
                            viewType: 'sweatlock/ios_selected_apps',
                            creationParamsCodec: const StandardMessageCodec(),
                            onPlatformViewCreated: (_) {},
                          ),
                        ),

                      if (blocked.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Text(
                            'No apps locked yet.\nTap below to start earning your screen time.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      else
                        ...blocked.map((app) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BlockedAppsDetailsScreen(app: app),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Theme.of(context).cardColor,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.primaryGreen
                                          .withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  app.appName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                subtitle: Text(
                                  'Unlock with ${app.requiredReps} ${app.exerciseType}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryGreen
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    app.appName.isNotEmpty
                                        ? app.appName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.lock_rounded,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          );
                        }),

                      16.height(),
                      CustomButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SelectAppsScreen(),
                            ),
                          );
                        },
                        text: blocked.isEmpty
                            ? 'Lock apps to reduce doomscrolling'
                            : 'Manage locked apps',
                      ),
                      8.height(),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WorkoutScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.fitness_center,
                              color: AppColors.primaryGreen),
                          label: const Text(
                            'Quick workout',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool wide = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
