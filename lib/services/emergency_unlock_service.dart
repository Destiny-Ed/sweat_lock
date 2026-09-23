import 'dart:io';

import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

class EmergencyUnlockResult {
  final bool success;
  final String message;
  final int remaining;
  final int unlockMinutes;

  const EmergencyUnlockResult({
    required this.success,
    required this.message,
    required this.remaining,
    required this.unlockMinutes,
  });
}

/// One-tap unlock of **all** locked apps (limited uses per day).
class EmergencyUnlockService {
  EmergencyUnlockService._();
  static final instance = EmergencyUnlockService._();

  Future<EmergencyUnlockResult> unlockAll() async {
    final remaining = HiveService.emergencyUnlocksRemaining();
    if (remaining <= 0) {
      return const EmergencyUnlockResult(
        success: false,
        message: 'No emergency unlocks left today. Come back tomorrow.',
        remaining: 0,
        unlockMinutes: 0,
      );
    }

    final mins = emergencyUnlockDurationMinutes;

    if (Platform.isAndroid) {
      await BlockingService.instance.grantUnlockAll(minutes: mins);
    }

    if (Platform.isIOS) {
      // Emergency intentionally unlocks everything on iOS
      await IosNudgeService.instance.onWorkoutCompleted(
        unlockMinutes: mins,
        unlockAll: true,
      );
    }

    final progress = HiveService.getProgress();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int used = progress.emergencyUnlocksUsedToday;
    if (progress.lastEmergencyUnlockDate != null) {
      final last = DateTime(
        progress.lastEmergencyUnlockDate!.year,
        progress.lastEmergencyUnlockDate!.month,
        progress.lastEmergencyUnlockDate!.day,
      );
      if (last != today) used = 0;
    }

    await HiveService.saveProgress(
      progress.copyWith(
        emergencyUnlocksUsedToday: used + 1,
        lastEmergencyUnlockDate: now,
      ),
    );

    final left = HiveService.emergencyUnlocksRemaining();
    return EmergencyUnlockResult(
      success: true,
      message:
          'All locked apps unlocked for $mins minutes. $left emergency unlock(s) left today.',
      remaining: left,
      unlockMinutes: mins,
    );
  }
}
