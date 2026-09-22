import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';

/// Full-screen overlay shown when a blocked app is opened.
/// This is the entry point for the accessibility overlay.
class BlockedOverlay extends StatelessWidget {
  const BlockedOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final package = BlockingService.instance.currentlyBlockedPackage;
    final blockedApps = HiveService.getBlockedApps();
    final matched = blockedApps.cast<dynamic>().firstWhere(
          (a) => a.packageName == package ||
              (package != null && package.contains(a.packageName)),
          orElse: () => null,
        );

    final appName = matched?.appName ?? 'This app';
    final reps = matched?.requiredReps ?? defaultReps;
    final exercise = matched?.exerciseType ?? defaultExercise;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 80, color: Color(0xFFFF2E63)),
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
                const SizedBox(height: 12),
                Text(
                  'Complete $reps $exercise to unlock',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkoutScreen(
                            targetReps: reps,
                            exerciseType: exercise,
                            unlockedAppId: matched?.id,
                          ),
                        ),
                      ).then((_) {
                        // After workout, grant unlock
                        BlockingService.instance.grantCurrentUnlock(
                          minutes: unlockDurationMinutes,
                        );
                      });
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
                  onPressed: () {
                    // Emergency unlock path can be added later
                    BlockingService.instance.hideBlockOverlay();
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
      ),
    );
  }
}
