import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/presentation/modals/single_list_modal.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';
import 'package:sweat_lock/data/local/hive_service.dart';

class BlockedAppsDetailsScreen extends StatefulWidget {
  final BlockedApp app;

  const BlockedAppsDetailsScreen({super.key, required this.app});

  @override
  State<BlockedAppsDetailsScreen> createState() =>
      _BlockedAppsDetailsScreenState();
}

class _BlockedAppsDetailsScreenState extends State<BlockedAppsDetailsScreen> {
  late BlockedApp _app;

  @override
  void initState() {
    super.initState();
    _app = widget.app;
  }

  Future<void> _swapExercise() async {
    await showGenrePickerBottomSheet(
      context: context,
      title: 'select workout',
      items: supportedExercises,
      currentSelected: _app.exerciseType,
      onGenreSelected: (workout) async {
        final updated = _app.copyWith(exerciseType: workout);
        await HiveService.addBlockedApp(updated);
        setState(() => _app = updated);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_app.appName)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppColors.primaryGreen.withValues(alpha: 0.2),
                    radius: 40,
                    child: Text(
                      _app.appName.isNotEmpty ? _app.appName[0] : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  16.height(),
                  Text(
                    '${_app.requiredReps} ${_app.exerciseType}'.cap,
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 28),
                  ),
                  8.height(),
                  Text(
                    'unlock for $unlockDurationMinutes minutes'.cap,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  8.height(),
                  Text(
                    _app.playlistName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                  ),
                  20.height(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.sports,
                                    color: AppColors.primaryGreen, size: 40),
                                Text(
                                  '${_app.requiredReps} reps'.cap,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                                Text(
                                  'required'.capitalize,
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.alarm,
                                    color: AppColors.primaryGreen, size: 40),
                                Text(
                                  '$unlockDurationMinutes mins'.cap,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge,
                                ),
                                Text(
                                  'earned'.capitalize,
                                  style:
                                      Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        15.height(),
                        Text(
                          "you've got this!".capitalize,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  40.height(),
                  CustomButton(
                    text: 'start workout',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutScreen(
                            targetReps: _app.requiredReps,
                            exerciseType: _app.exerciseType,
                            unlockedAppId: _app.id,
                            playlistName: _app.playlistName,
                            playlistUrl: _app.playlistUrl,
                            appName: _app.appName,
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: _swapExercise,
                    child: Text(
                      'swap exercise'.cap,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
