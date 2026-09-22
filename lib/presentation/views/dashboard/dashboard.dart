import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/extensions.dart';
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

  @override
  Widget build(BuildContext context) {
    final progress = HiveService.getProgress();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.person),
        title: const Text('Good morning'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: Consumer<BlockingProvider>(
        builder: (context, blockingVm, _) {
          final blocked = blockingVm.blockedApps;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).cardColor,
                        radius: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${progress.totalReps}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            Text(
                              'Total reps',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      10.height(),
                      Text(
                        '${progress.currentStreak} day streak',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      30.height(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Blocked Apps',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      15.height(),
                      if (blocked.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No apps locked yet.\nTap below to start.',
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
                                      const BlockedAppsDetailsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Theme.of(context).cardColor,
                              ),
                              child: ListTile(
                                title: Text(
                                  app.appName,
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                subtitle: Text(
                                  'Blocked until ${app.requiredReps} ${app.exerciseType}',
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .secondaryHeaderColor,
                                  child: const Icon(Icons.apps),
                                ),
                                trailing: Icon(
                                  Icons.lock,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          );
                        }),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        child: CustomButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SelectAppsScreen(),
                              ),
                            );
                          },
                          text: blocked.isEmpty
                              ? 'Block apps to reduce doomscrolling'
                              : 'Manage locked apps',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WorkoutScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Quick workout'),
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
}
