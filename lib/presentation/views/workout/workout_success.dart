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
  final bool completed;

  const WorkoutSuccessScreen({
    super.key,
    this.reps,
    this.exerciseType,
    this.appName,
    this.completed = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = HiveService.getProgress();
    final sessions = HiveService.getAllSessions();
    final last = sessions.isNotEmpty ? sessions.first : null;

    final doneReps = reps ?? last?.completedReps ?? defaultReps;
    final exercise = exerciseType ?? last?.exerciseType ?? defaultExercise;
    final unlockMins = HiveService.getUnlockDurationMinutes();
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
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppColors.primaryGreen,
                  ),
                  20.height(),
                  Text(
                    '$unlockedApp unlocked for $unlockMins mins'.cap,
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
                  30.height(),
                  CustomButton(
                    text: 'Done'.cap,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        // Overlay path: return true so unlock is granted
                        Navigator.of(context).pop(completed);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainActivity(),
                          ),
                          (_) => false,
                        );
                      }
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
