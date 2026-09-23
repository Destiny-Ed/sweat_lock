import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

/// Walk [goal] steps (from session start) to unlock the locked app.
class StepsUnlockScreen extends StatefulWidget {
  final String? unlockedAppId;
  final String? appName;
  final int? goal;

  const StepsUnlockScreen({
    super.key,
    this.unlockedAppId,
    this.appName,
    this.goal,
  });

  @override
  State<StepsUnlockScreen> createState() => _StepsUnlockScreenState();
}

class _StepsUnlockScreenState extends State<StepsUnlockScreen> {
  StreamSubscription<StepCount>? _sub;
  int? _baseline;
  int _sessionSteps = 0;
  bool _unlocking = false;
  String? _error;

  int get _goal => widget.goal ?? HiveService.getStepGoal();

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        setState(() => _error = 'Activity recognition permission is required.');
        return;
      }
    }
    if (Platform.isIOS) {
      // Motion permission is prompted by the OS when stream starts.
    }

    try {
      _sub = Pedometer.stepCountStream.listen(
        (event) {
          if (_baseline == null) {
            _baseline = event.steps;
          }
          final delta = event.steps - (_baseline ?? event.steps);
          setState(() => _sessionSteps = delta < 0 ? 0 : delta);
          if (_sessionSteps >= _goal) {
            _complete();
          }
        },
        onError: (e) {
          setState(() => _error = 'Could not read steps: $e');
        },
      );
    } catch (e) {
      setState(() => _error = 'Pedometer unavailable: $e');
    }
  }

  Future<void> _complete() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);

    final mins = HiveService.getUnlockDurationMinutes();
    final appId = widget.unlockedAppId ?? HiveService.getLastBlockedAppId();

    if (Platform.isAndroid) {
      await BlockingService.instance.grantUnlockForAppId(appId, minutes: mins);
      await BlockingService.instance.startListening();
    } else if (Platform.isIOS) {
      String? bundleId;
      if (appId != null) {
        for (final a in HiveService.getBlockedApps()) {
          if (a.id == appId && a.bundleId.isNotEmpty) {
            bundleId = a.bundleId;
            break;
          }
        }
      }
      await IosNudgeService.instance.onWorkoutCompleted(
        unlockMinutes: mins,
        bundleId: bundleId,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_sessionSteps / _goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.appName ?? 'Walk to unlock'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: _error != null
            ? Center(
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_walk,
                      size: 72, color: AppColors.primaryGreen),
                  const SizedBox(height: 24),
                  Text(
                    '$_sessionSteps / $_goal steps',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Walk with your phone — steps count from this session only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 28),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: Colors.white24,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 40),
                  if (_sessionSteps >= _goal)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _unlocking ? null : _complete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Unlock now',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
