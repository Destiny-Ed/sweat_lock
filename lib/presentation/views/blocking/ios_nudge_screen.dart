import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/presentation/views/reading/reading_unlock_screen.dart';
import 'package:sweat_lock/presentation/views/steps/steps_unlock_screen.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';
import 'package:sweat_lock/services/schedule_service.dart';

class IosNudgeScreen extends StatefulWidget {
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
  State<IosNudgeScreen> createState() => _IosNudgeScreenState();
}

class _IosNudgeScreenState extends State<IosNudgeScreen> {
  BlockedApp? _matched;
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _matched = _resolveMatched();
    _displayName = widget.appName ??
        _matched?.appName ??
        (HiveService.getBlockedApps().isNotEmpty
            ? HiveService.getBlockedApps().first.appName
            : 'This app');

    // Always persist so reading/workout/quiz can unlock THIS app
    final m = _matched;
    if (m != null) {
      HiveService.setLastBlockedAppId(m.id);
      if (m.bundleId.isNotEmpty) {
        HiveService.setLastBlockedPackage(m.bundleId);
      } else if (m.packageName.isNotEmpty) {
        HiveService.setLastBlockedPackage(m.packageName);
      }
    } else if (widget.bundleId != null && widget.bundleId!.isNotEmpty) {
      HiveService.setLastBlockedPackage(widget.bundleId!);
    }
  }

  BlockedApp? _resolveMatched() {
    final apps = HiveService.getBlockedApps().where((a) => a.isActive).toList();
    final bid = widget.bundleId;

    if (bid != null && bid.isNotEmpty) {
      for (final a in apps) {
        if (a.bundleId == bid ||
            (a.bundleId.isNotEmpty &&
                (a.bundleId.contains(bid) || bid.contains(a.bundleId)))) {
          return a;
        }
      }
    }

    final lastId = HiveService.getLastBlockedAppId();
    if (lastId != null) {
      for (final a in apps) {
        if (a.id == lastId) return a;
      }
    }

    final lastPkg = HiveService.getLastBlockedPackage();
    if (lastPkg != null && lastPkg.isNotEmpty) {
      for (final a in apps) {
        if (a.bundleId == lastPkg ||
            a.packageName == lastPkg ||
            (a.bundleId.isNotEmpty && lastPkg.contains(a.bundleId))) {
          return a;
        }
      }
    }

    // Single locked app → that one
    if (apps.length == 1) return apps.first;

    // Prefer any iOS app with a bundle id
    for (final a in apps) {
      if (a.bundleId.isNotEmpty) return a;
    }
    return apps.isNotEmpty ? apps.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final matched = _matched;
    final displayName = _displayName;
    final reps = matched?.requiredReps ?? defaultReps;
    final exercise = matched?.exerciseType ?? defaultExercise;
    final isSteps = exercise == 'steps';
    final canRead = HiveService.getReadingUnlockEnabled() &&
        (HiveService.getReadingPdfPath()?.isNotEmpty ?? false);
    final canSteps = HiveService.getStepsUnlockEnabled();
    final unlockMins = HiveService.getUnlockDurationMinutes();
    final stepGoal = isSteps && reps >= 100 ? reps : HiveService.getStepGoal();
    final inFocus = ScheduleService.instance.isInFocusWindow;
    final appId = matched?.id;

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
              if (inFocus) ...[
                const SizedBox(height: 8),
                const Text(
                  'Focus schedule active',
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'About ${widget.usageMinutes} min on $displayName.\n'
                'Unlock with real form, steps, or read + quiz — not a skim.\n'
                'Free window after unlock: $unlockMins minutes, then lock returns.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (isSteps) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StepsUnlockScreen(
                            unlockedAppId: appId,
                            appName: displayName,
                            goal: stepGoal,
                          ),
                        ),
                      );
                    } else {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkoutScreen(
                            targetReps: reps,
                            exerciseType: exercise,
                            unlockedAppId: appId,
                            appName: displayName,
                          ),
                        ),
                      );
                    }
                    if (widget.bundleId != null && widget.bundleId!.isNotEmpty) {
                      await IosNudgeService.instance
                          .resetUsageForApp(widget.bundleId!);
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: Icon(
                      isSteps ? Icons.directions_walk : Icons.fitness_center),
                  label: Text(
                    isSteps
                        ? 'Walk $stepGoal steps'
                        : 'Workout · $reps $exercise',
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
              if (!isSteps && canSteps) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => StepsUnlockScreen(
                            unlockedAppId: appId,
                            appName: displayName,
                            goal: stepGoal,
                          ),
                        ),
                      );
                      if (ok == true && context.mounted) {
                        if (widget.bundleId != null &&
                            widget.bundleId!.isNotEmpty) {
                          await IosNudgeService.instance
                              .resetUsageForApp(widget.bundleId!);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.directions_walk),
                    label: Text('Walk $stepGoal steps'),
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
                            unlockedAppId: appId,
                            appName: displayName,
                          ),
                        ),
                      );
                      if (ok == true && context.mounted) {
                        if (widget.bundleId != null &&
                            widget.bundleId!.isNotEmpty) {
                          await IosNudgeService.instance
                              .resetUsageForApp(widget.bundleId!);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      }
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
