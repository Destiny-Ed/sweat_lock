import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

/// Full-screen soft nudge shown on iOS when usage limit is reached.
class IosNudgeScreen extends StatelessWidget {
  final String? bundleId;
  final int usageMinutes;

  const IosNudgeScreen({
    super.key,
    this.bundleId,
    this.usageMinutes = 25,
  });

  @override
  Widget build(BuildContext context) {
    final apps = HiveService.getBlockedApps();
    final matched = apps.cast<dynamic>().firstWhere(
          (a) => a.bundleId == bundleId || (bundleId != null && a.bundleId.contains(bundleId!)),
          orElse: () => null,
        );

    final appName = matched?.appName ?? 'Your app';
    final reps = matched?.requiredReps ?? defaultReps;
    final exercise = matched?.exerciseType ?? defaultExercise;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, size: 80, color: Color(0xFFFF2E63)),
              const SizedBox(height: 24),
              Text(
                'Time for a break',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You've used $appName for about $usageMinutes minutes.\nComplete $reps $exercise to continue mindfully.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 48),
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
                        ),
                      ),
                    );
                    // After workout, reset usage tracking for this app
                    if (bundleId != null && bundleId!.isNotEmpty) {
                      await IosNudgeService.instance.resetUsageForApp(bundleId!);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text(
                    'Start Workout',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Remind me later',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'iOS limits real-time blocking.\nThis smart nudge helps you stay consistent.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
