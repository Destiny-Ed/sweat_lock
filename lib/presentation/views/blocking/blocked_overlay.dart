import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';

/// Full-screen overlay shown when a blocked app is opened.
class BlockedOverlay extends StatelessWidget {
  const BlockedOverlay({super.key});

  BlockedApp? _match(String? package) {
    if (package == null) return null;
    final blockedApps = HiveService.getBlockedApps();
    for (final a in blockedApps) {
      if (a.packageName == package || package.contains(a.packageName)) {
        return a;
      }
    }
    return null;
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                const SizedBox(height: 12),
                Text(
                  'Complete $reps $exercise to unlock',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                if (matched != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Playlist: $playlistName',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryGreen.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
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
                      )
                          .then((_) {
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
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.black,
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
