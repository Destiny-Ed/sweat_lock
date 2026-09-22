import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class WorkoutSuccessScreen extends StatelessWidget {
  final int? reps;
  final String? exerciseType;
  final String? appName;

  const WorkoutSuccessScreen({
    super.key,
    this.reps,
    this.exerciseType,
    this.appName,
  });

  @override
  Widget build(BuildContext context) {
    final progress = HiveService.getProgress();
    final sessions = HiveService.getAllSessions();
    final last = sessions.isNotEmpty ? sessions.first : null;

    final doneReps = reps ?? last?.completedReps ?? defaultReps;
    final exercise = exerciseType ?? last?.exerciseType ?? defaultExercise;
    String unlockedApp = appName ?? 'your apps';
    if (appName == null && last?.unlockedAppId != null) {
      final apps = HiveService.getBlockedApps();
      for (final a in apps) {
        if (a.id == last!.unlockedAppId) {
          unlockedApp = a.appName;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    '$doneReps perfect $exercise'.cap,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 24),
                  ),
                  20.height(),
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.primaryGreen,
                  ),
                  20.height(),
                  Text(
                    '$unlockedApp unlocked for $unlockDurationMinutes mins'.cap,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  20.height(),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryGreen),
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    child: ListTile(
                      title: Text(
                        'Streak update'.cap,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryGreen,
                            ),
                      ),
                      subtitle: Text(
                        '${progress.currentStreak} day streak · ${progress.totalReps} lifetime reps'
                            .cap,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      trailing: CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).cardColor,
                        child: const Icon(Icons.local_fire_department),
                      ),
                    ),
                  ),
                  20.height(),
                  Container(
                    width: context.screenSize().width,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.share,
                          color: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.color
                              ?.darken(),
                        ),
                        8.height(),
                        Text(
                          '"I just did $doneReps $exercise to earn $unlockedApp"'
                              .cap,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primaryGreen,
                              ),
                        ),
                        Text(
                          'your shareable story template'.cap,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  30.height(),
                  CustomButton(
                    text: 'Back to home'.cap,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainActivity(),
                        ),
                        (_) => false,
                      );
                    },
                  ),
                  12.height(),
                  CustomButton(
                    text: 'share to stories'.cap,
                    bgColor: Theme.of(context).secondaryHeaderColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
