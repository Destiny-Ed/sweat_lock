import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';
import 'package:sweat_lock/services/accountability_feed_service.dart';

class WorkoutSuccessScreen extends StatefulWidget {
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
  State<WorkoutSuccessScreen> createState() => _WorkoutSuccessScreenState();
}

class _WorkoutSuccessScreenState extends State<WorkoutSuccessScreen> {
  bool _queued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _queueWin());
  }

  Future<void> _queueWin() async {
    if (_queued || !widget.completed) return;
    _queued = true;

    final sessions = HiveService.getAllSessions();
    final last = sessions.isNotEmpty ? sessions.first : null;
    final doneReps = widget.reps ?? last?.completedReps ?? defaultReps;
    final exercise =
        widget.exerciseType ?? last?.exerciseType ?? defaultExercise;
    String unlockedApp = widget.appName ?? 'your app';
    if (widget.appName == null && last?.unlockedAppId != null) {
      for (final a in HiveService.getBlockedApps()) {
        if (a.id == last!.unlockedAppId) {
          unlockedApp = a.appName;
          break;
        }
      }
    }

    await AccountabilityFeedService.instance.recordWin(
      appName: unlockedApp,
      challenge: '$doneReps $exercise',
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = HiveService.getProgress();
    final sessions = HiveService.getAllSessions();
    final last = sessions.isNotEmpty ? sessions.first : null;

    final doneReps = widget.reps ?? last?.completedReps ?? defaultReps;
    final exercise =
        widget.exerciseType ?? last?.exerciseType ?? defaultExercise;
    final unlockMins = HiveService.getUnlockDurationMinutes();
    String unlockedApp = widget.appName ?? 'your app';
    if (widget.appName == null && last?.unlockedAppId != null) {
      for (final a in HiveService.getBlockedApps()) {
        if (a.id == last!.unlockedAppId) {
          unlockedApp = a.appName;
          break;
        }
      }
    }

    final shareText = AccountabilityFeedService.instance.buildWinShareText(
      appName: unlockedApp,
      challenge: '$doneReps $exercise',
    );

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
                    '$unlockedApp unlocked for $unlockMins min'.cap,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  12.height(),
                  Text(
                    'Only this app. When the timer ends, SweatLock locks it again automatically — no free pass forever.'
                        .cap,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
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
                  16.height(),
                  OutlinedButton.icon(
                    onPressed: () =>
                        AccountabilityFeedService.instance.shareText(shareText),
                    icon: const Icon(Icons.ios_share,
                        color: AppColors.primaryGreen),
                    label: const Text(
                      'Share this win',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  24.height(),
                  CustomButton(
                    text: 'Done'.cap,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(widget.completed);
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
