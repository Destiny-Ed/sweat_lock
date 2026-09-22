import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/user_progress.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/views/blocking/select_apps_screen.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';
import 'package:sweat_lock/services/blocking_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _reps;
  late String _exercise;
  late UserProgress _progress;

  @override
  void initState() {
    super.initState();
    _reps = HiveService.getDefaultReps().toDouble();
    _exercise = HiveService.getDefaultExercise();
    _progress = HiveService.getProgress();
  }

  Future<void> _useEmergencyUnlock() async {
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

    if (used >= emergencyUnlocksPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency unlocks left today')),
      );
      return;
    }

    if (Platform.isAndroid) {
      BlockingService.instance.grantCurrentUnlock(minutes: unlockDurationMinutes);
    }

    final updated = progress.copyWith(
      emergencyUnlocksUsedToday: used + 1,
      lastEmergencyUnlockDate: now,
    );
    await HiveService.saveProgress(updated);
    setState(() => _progress = updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency unlock used')),
      );
    }
  }

  int get _emergencyLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int used = _progress.emergencyUnlocksUsedToday;
    if (_progress.lastEmergencyUnlockDate != null) {
      final last = DateTime(
        _progress.lastEmergencyUnlockDate!.year,
        _progress.lastEmergencyUnlockDate!.month,
        _progress.lastEmergencyUnlockDate!.day,
      );
      if (last != today) used = 0;
    }
    return (emergencyUnlocksPerDay - used).clamp(0, emergencyUnlocksPerDay);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = context.watch<BlockingProvider>().blockedApps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Exercise Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reps per session',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${_reps.round()}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Slider(
                          value: _reps,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) {
                            setState(() => _reps = v);
                          },
                          onChangeEnd: (v) {
                            HiveService.setDefaultReps(v.round());
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Default exercise',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: supportedExercises.map((e) {
                            final selected = e == _exercise;
                            return ChoiceChip(
                              label: Text(e),
                              selected: selected,
                              selectedColor: AppColors.primaryGreen,
                              onSelected: (_) {
                                setState(() => _exercise = e);
                                HiveService.setDefaultExercise(e);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Locked Apps',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      children: [
                        if (blocked.isEmpty)
                          ListTile(
                            title: Text(
                              'No apps locked',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SelectAppsScreen(),
                                  ),
                                );
                              },
                              child: const Text('Add'),
                            ),
                          )
                        else
                          ...blocked.take(5).map(
                                (app) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    app.appName,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  subtitle: Text(
                                    '${app.requiredReps} ${app.exerciseType}',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .secondaryHeaderColor,
                                    child: const Icon(Icons.apps),
                                  ),
                                  trailing: const Icon(
                                    Icons.lock,
                                    size: 18,
                                  ),
                                ),
                              ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SelectAppsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Manage locked apps',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Security & Access',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _useEmergencyUnlock,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Emergency Unlock',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).secondaryHeaderColor,
                            ),
                            child: Text(
                              '$_emergencyLeft left today'.cap,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.primaryGreen),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.primaryGreen,
                            child: const Icon(Icons.star_outline,
                                color: Colors.black),
                          ),
                          title: Text(
                            'Upgrade to premium'.cap,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            'Unlock custom exercises, unlimited unlocks, and advanced stats'
                                .capitalize,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        CustomButton(
                          text: 'Go unlimited'.cap,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Premium coming soon'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  _aboutTile(context, 'About $appName', Icons.info),
                  const SizedBox(height: 10),
                  _aboutTile(context, 'Contact Support', Icons.support_agent),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutTile(BuildContext context, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Icon(icon, color: Theme.of(context).textTheme.titleLarge?.color),
        ],
      ),
    );
  }
}
