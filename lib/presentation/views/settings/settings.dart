import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/user_progress.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/blocking/select_apps_screen.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _reps;
  late String _exercise;
  late UserProgress _progress;
  late String _blockMode;
  late double _freeMinutes;
  late double _warningMinutes;
  late double _unlockMinutes;
  late bool _notifications;
  late bool _preventUninstall;
  bool _accessibilityOn = false;
  String _screenTimeStatus = 'unknown';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _reps = HiveService.getDefaultReps().toDouble();
    _exercise = HiveService.getDefaultExercise();
    _progress = HiveService.getProgress();
    _blockMode = HiveService.getBlockMode();
    _freeMinutes = HiveService.getFreeMinutes().toDouble();
    _warningMinutes = HiveService.getWarningMinutes().toDouble();
    _unlockMinutes = HiveService.getUnlockDurationMinutes().toDouble();
    _notifications = HiveService.getNotificationsEnabled();
    _preventUninstall = HiveService.getPreventUninstall();

    if (Platform.isAndroid) {
      _accessibilityOn =
          await BlockingService.instance.isAccessibilityEnabled();
    }
    if (Platform.isIOS) {
      // status string from channel if available
      _screenTimeStatus = 'check below';
    }
    if (mounted) setState(() {});
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
      BlockingService.instance.grantCurrentUnlock(
        minutes: HiveService.getUnlockDurationMinutes(),
      );
    }
    if (Platform.isIOS) {
      await IosNudgeService.instance.onWorkoutCompleted(
        unlockMinutes: HiveService.getUnlockDurationMinutes(),
      );
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

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'This clears local locked apps and progress on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (Platform.isIOS) {
      await IosNudgeService.instance.clearShield();
      await IosNudgeService.instance.stopMonitoring();
    }
    await HiveService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  Future<void> _applyMonitoringPrefs() async {
    if (Platform.isIOS) {
      await IosNudgeService.instance.startMonitoring();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blocking preferences applied')),
      );
    }
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).cardColor,
      ),
      child: child,
    );
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
          SniverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // ---- Blocking mode ----
                  Text('Blocking preference',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Platform.isIOS
                              ? 'How selected apps are locked'
                              : 'How locked apps are blocked',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Immediate'),
                          subtitle: Text(
                            Platform.isIOS
                                ? 'Shield apps right after selection'
                                : 'Block as soon as the app is opened',
                          ),
                          value: 'immediate',
                          groupValue: _blockMode,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => _blockMode = v);
                            await HiveService.setBlockMode(v);
                            await _applyMonitoringPrefs();
                          },
                        ),
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Timed free window'),
                          subtitle: const Text(
                            'Allow use for a few minutes, then lock',
                          ),
                          value: 'timed',
                          groupValue: _blockMode,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => _blockMode = v);
                            await HiveService.setBlockMode(v);
                            await _applyMonitoringPrefs();
                          },
                        ),
                        if (_blockMode == 'timed') ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Free minutes',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text('${_freeMinutes.round()}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          Slider(
                            value: _freeMinutes,
                            min: 1,
                            max: 60,
                            divisions: 59,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (v) =>
                                setState(() => _freeMinutes = v),
                            onChangeEnd: (v) async {
                              await HiveService.setFreeMinutes(v.round());
                              await _applyMonitoringPrefs();
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Warn before lock (min)',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text('${_warningMinutes.round()}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          Slider(
                            value: _warningMinutes,
                            min: 1,
                            max: 15,
                            divisions: 14,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (v) =>
                                setState(() => _warningMinutes = v),
                            onChangeEnd: (v) async {
                              await HiveService.setWarningMinutes(v.round());
                              await _applyMonitoringPrefs();
                            },
                          ),
                        ],
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Unlock duration (min)',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            Text('${_unlockMinutes.round()}',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        Slider(
                          value: _unlockMinutes,
                          min: 5,
                          max: 120,
                          divisions: 23,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) =>
                              setState(() => _unlockMinutes = v),
                          onChangeEnd: (v) {
                            HiveService.setUnlockDurationMinutes(v.round());
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('Permissions',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _card(
                    Column(
                      children: [
                        if (Platform.isAndroid)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Accessibility service'),
                            subtitle: Text(
                              _accessibilityOn
                                  ? 'Enabled — apps can be blocked'
                                  : 'Required for Android blocking',
                            ),
                            value: _accessibilityOn,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (_) async {
                              await BlockingService.instance
                                  .requestAccessibilityPermission();
                              final on = await BlockingService.instance
                                  .isAccessibilityEnabled();
                              setState(() => _accessibilityOn = on);
                              if (on) {
                                await BlockingService.instance.startListening();
                              }
                            },
                          ),
                        if (Platform.isIOS)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Screen Time / Family Controls'),
                            subtitle: const Text(
                              'Authorize to select & shield apps',
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                final ok = await IosNudgeService.instance
                                    .requestAuthorization();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Screen Time approved'
                                            : 'Authorization denied or pending',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Authorize'),
                            ),
                          ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notifications'),
                          subtitle: const Text(
                            'Warnings before lock & unlock ended',
                          ),
                          value: _notifications,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) async {
                            setState(() => _notifications = v);
                            await HiveService.setNotificationsEnabled(v);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('Security',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _card(
                    Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Discourage uninstall'),
                          subtitle: Text(
                            Platform.isAndroid
                                ? 'Opens device admin / protection settings when available'
                                : 'iOS cannot block uninstall without MDM',
                          ),
                          value: _preventUninstall,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) async {
                            setState(() => _preventUninstall = v);
                            await HiveService.setPreventUninstall(v);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    Platform.isIOS
                                        ? 'iOS does not allow apps to prevent uninstall'
                                        : v
                                            ? 'Enable device admin in system settings for stronger protection'
                                            : 'Uninstall protection preference saved',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Emergency unlock'),
                          trailing: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).secondaryHeaderColor,
                            ),
                            child: Text(
                              '$_emergencyLeft left today'.cap,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          onTap: _useEmergencyUnlock,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('Exercise',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reps per session',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            Text('${_reps.round()}',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        Slider(
                          value: _reps,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (v) => setState(() => _reps = v),
                          onChangeEnd: (v) =>
                              HiveService.setDefaultReps(v.round()),
                        ),
                        Text('Default exercise',
                            style: Theme.of(context).textTheme.titleMedium),
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
                  Text('Locked apps',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _card(
                    Column(
                      children: [
                        if (blocked.isEmpty)
                          const ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('No apps locked'),
                          )
                        else
                          ...blocked.take(8).map(
                                (app) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(app.appName),
                                  subtitle: Text(
                                    '${app.requiredReps} ${app.exerciseType}',
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryGreen
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      app.appName.isNotEmpty
                                          ? app.appName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
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
                  Text('Account',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _card(
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Log out'),
                      trailing: const Icon(Icons.logout),
                      onTap: _logout,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('About',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _card(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('About $appName',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Icon(Icons.info_outline),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
