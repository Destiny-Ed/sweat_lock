import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/presentation/providers/workout_provider.dart';
import 'package:sweat_lock/presentation/views/workout/workout_success.dart';

class WorkoutScreen extends StatefulWidget {
  final int? targetReps;
  final String? exerciseType;
  final String? unlockedAppId;

  const WorkoutScreen({
    super.key,
    this.targetReps,
    this.exerciseType,
    this.unlockedAppId,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<WorkoutProvider>();
      await vm.init(
        targetReps: widget.targetReps,
        exerciseType: widget.exerciseType,
        unlockedAppId: widget.unlockedAppId,
      );
      await vm.startWorkout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutVm, child) {
        // Auto navigate on completion
        if (!workoutVm.isWorkoutActive &&
            workoutVm.currentReps >= workoutVm.targetReps &&
            workoutVm.currentReps > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkoutSuccessScreen(),
                ),
              );
            }
          });
        }

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              if (workoutVm.isLoading || workoutVm.controller == null)
                const Center(child: CircularProgressIndicator())
              else
                CameraPreview(workoutVm.controller!),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await workoutVm.stopWorkout(completed: false);
                            if (mounted) Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black54,
                            ),
                            child: Text(
                              'End',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        CircularPercentIndicator(
                          radius: 48,
                          lineWidth: 6,
                          percent: workoutVm.progress,
                          animation: false,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${workoutVm.currentReps}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '/${workoutVm.targetReps}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.white24,
                          progressColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Feedback text
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    workoutVm.feedback,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.red,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                  ),
                ),
              ),

              // Bottom exercise info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        workoutVm.exerciseType.cap,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${workoutVm.currentReps} / ${workoutVm.targetReps} reps',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: workoutVm.progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: Colors.white24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
