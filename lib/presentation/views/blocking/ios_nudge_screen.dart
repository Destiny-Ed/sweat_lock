import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/views/reading/reading_unlock_screen.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

/// Full-screen nudge when usage limit is reached.
class IosNudgeScreen extends StatelessWidget {
  final String? bundleId;
  final String? appName;
  final int usageMinutes;

  const IosNudgeScreen({
    super.key,
    this.bundleId,
    this.appName,
    this.usageMinutes = 25,
  });

  @override
  Widget build(BuildContext context) {
    final apps = HiveService.getBlockedApps();
    dynamic matched;
    for (final a in apps) {
      if (bundleId != null &&
          (a.bundleId == bundleId || a.bundleId.contains(bundleId!))) {
        matched = a;
        break;
      }
    }

    final displayName = appName ??
        matched?.appName ??
        (apps.isNotEmpty ? apps.first.appName : 'This app');
    final reps = matched?.requiredReps ?? defaultReps;
    final exercise = matched?.exerciseType ?? defaultExercise;
    final canRead = HiveService.getReadingUnlockEnabled() &&
        (HiveService.getReadingPdfPath()?.isNotEmpty ?? false);

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
                  Icons.lock_clock,
                  size: 72,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '$displayName is limited',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You've used about $usageMinutes min on $displayName.\n"
                'Workout or read $requiredReadingPages pages to unlock.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutScreen(
                          targetReps: reps,
                          exerciseType: exercise,
                          unlockedAppId: matched?.id,
                          appName: displayName,
                        ),
                      ),
                    );
                    if (bundleId != null && bundleId!.isNotEmpty) {
                      await IosNudgeService.instance.resetUsageForApp(bundleId!);
                    }
                    if (context.mounted) Navigator.of(context).pop();
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
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
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
                            appName: displayName,
                          ),
                        ),
                      );
                      if (ok == true && context.mounted) {
                        if (bundleId != null && bundleId!.isNotEmpty) {
                          await IosNudgeService.instance
                              .resetUsageForApp(bundleId!);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.menu_book),
                    label: Text(
                      'Read $requiredReadingPages pages instead',
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Remind me later',
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
