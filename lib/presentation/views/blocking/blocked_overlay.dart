import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/presentation/providers/workout_provider.dart';
import 'package:sweat_lock/presentation/views/reading/reading_unlock_screen.dart';
import 'package:sweat_lock/presentation/views/steps/steps_unlock_screen.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/schedule_service.dart';

class BlockedOverlay extends StatelessWidget {
  const BlockedOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkoutProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _BlockedOverlayHome(),
      ),
    );
  }
}

class _BlockedOverlayHome extends StatelessWidget {
  const _BlockedOverlayHome();

  BlockedApp? _match(String? package) {
    if (package == null) return null;
    final blockedApps = HiveService.getBlockedApps();
    for (final a in blockedApps) {
      if (a.packageName == package ||
          package.contains(a.packageName) ||
          a.packageName.contains(package)) {
        return a;
      }
    }
    return null;
  }

  Future<void> _afterUnlock(String? package) async {
    if (package == null) return;
    await BlockingService.instance.grantTemporaryUnlock(
      package,
      minutes: HiveService.getUnlockDurationMinutes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final package = BlockingService.instance.currentlyBlockedPackage;
    final matched = _match(package);

    final appName = matched?.appName ?? 'This app';
    final reps = matched?.requiredReps ?? defaultReps;
    final exercise = matched?.exerciseType ?? defaultExercise;
    final playlistName = matched?.playlistName ?? 'Workout Mix';
    final playlistUrl = matched?.playlistUrl;
    final isStepsPrimary = exercise == 'steps';
    final canRead = HiveService.getReadingUnlockEnabled() &&
        (HiveService.getReadingPdfPath()?.isNotEmpty ?? false);
    final canSteps = HiveService.getStepsUnlockEnabled();
    final stepGoal = isStepsPrimary
        ? (reps >= 100 ? reps : HiveService.getStepGoal())
        : HiveService.getStepGoal();
    final unlockMins = HiveService.getUnlockDurationMinutes();
    final inFocus = ScheduleService.instance.isInFocusWindow;

    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 72,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '$appName is locked',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (inFocus) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Focus schedule · hard lock',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                isStepsPrimary
                    ? 'Walk $stepGoal real steps. Then $appName opens for $unlockMins min only — then locks again.'
                    : 'Real pose reps, a real walk, or read with a quiz — not hand-waving or skimming. Unlock is $unlockMins min for this app only.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 8),
              Text(
                'After $unlockMins minutes free, monitoring restarts automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryGreen.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              if (isStepsPrimary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => StepsUnlockScreen(
                            unlockedAppId: matched?.id,
                            appName: appName,
                            goal: stepGoal,
                          ),
                        ),
                      );
                      if (ok == true) await _afterUnlock(package);
                    },
                    icon: const Icon(Icons.directions_walk),
                    label: Text(
                      'Walk $stepGoal steps',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final completed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => WorkoutScreen(
                            targetReps: reps,
                            exerciseType: exercise,
                            unlockedAppId: matched?.id,
                            playlistName: playlistName,
                            playlistUrl: playlistUrl,
                            appName: appName,
                          ),
                        ),
                      );
                      if (completed == true) await _afterUnlock(package);
                    },
                    icon: const Icon(Icons.fitness_center),
                    label: Text(
                      'Workout · $reps $exercise',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              if (!isStepsPrimary && canSteps) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => StepsUnlockScreen(
                            unlockedAppId: matched?.id,
                            appName: appName,
                            goal: stepGoal,
                          ),
                        ),
                      );
                      if (ok == true) await _afterUnlock(package);
                    },
                    icon: const Icon(Icons.directions_walk),
                    label: Text(
                      'Walk $stepGoal steps',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
              if (isStepsPrimary) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final completed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => WorkoutScreen(
                            targetReps: defaultReps,
                            exerciseType: 'push-ups',
                            unlockedAppId: matched?.id,
                            playlistName: playlistName,
                            playlistUrl: playlistUrl,
                            appName: appName,
                          ),
                        ),
                      );
                      if (completed == true) await _afterUnlock(package);
                    },
                    icon: const Icon(Icons.fitness_center),
                    label: const Text(
                      'Workout instead',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
              if (canRead) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ReadingUnlockScreen(
                            unlockedAppId: matched?.id,
                            appName: appName,
                          ),
                        ),
                      );
                      if (ok == true) await _afterUnlock(package);
                    },
                    icon: const Icon(Icons.menu_book),
                    label: Text(
                      'Read + quiz ($requiredReadingPages pages)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await BlockingService.instance.hideBlockOverlay();
                },
                child: const Text(
                  'Not now',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
