import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/presentation/providers/workout_provider.dart';
import 'package:sweat_lock/presentation/views/reading/reading_unlock_screen.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';

/// Full-screen overlay when a blocked app is opened (Android accessibility).
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

  @override
  Widget build(BuildContext context) {
    final package = BlockingService.instance.currentlyBlockedPackage;
    final matched = _match(package);

    final appName = matched?.appName ?? 'This app';
    final reps = matched?.requiredReps ?? defaultReps;
    final exercise = matched?.exerciseType ?? defaultExercise;
    final playlistName = matched?.playlistName ?? 'Workout Mix';
    final playlistUrl = matched?.playlistUrl;
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
                'Complete $reps $exercise'
                '${canRead ? ' or read $requiredReadingPages pages' : ''}'
                ' to unlock.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, color: Colors.white70, height: 1.4),
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
              const SizedBox(height: 40),
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
                    if (completed == true && package != null) {
                      await BlockingService.instance.grantTemporaryUnlock(
                        package,
                        minutes: HiveService.getUnlockDurationMinutes(),
                      );
                    }
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
                      if (ok == true && package != null) {
                        await BlockingService.instance.grantTemporaryUnlock(
                          package,
                          minutes: HiveService.getUnlockDurationMinutes(),
                        );
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
                onPressed: () async {
                  // Dismiss overlay only — does NOT unlock (same as iOS later)
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
