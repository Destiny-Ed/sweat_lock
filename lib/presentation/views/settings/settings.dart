import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/providers/theme_provider.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/blocking/select_apps_screen.dart';
import 'package:sweat_lock/presentation/views/settings/accountability_screen.dart';
import 'package:sweat_lock/presentation/views/settings/focus_schedule_screen.dart';
import 'package:sweat_lock/presentation/views/settings/public_accountability_screen.dart';
import 'package:sweat_lock/presentation/views/settings/uninstall_guide_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/emergency_unlock_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _reps;
  late String _exercise;
  late String _blockMode;
  late double _freeMinutes;
  late double _unlockMinutes;
  late bool _notifications;
  late bool _readingEnabled;
  late bool _stepsEnabled;
  late double _stepGoal;
  String? _pdfPath;
  bool _accessibilityOn = false;
  int _emergencyLeft = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _reps = HiveService.getDefaultReps().toDouble();
    _exercise = HiveService.getDefaultExercise();
    _blockMode = HiveService.getBlockMode();
    _freeMinutes = HiveService.getFreeMinutes().toDouble();
    _unlockMinutes = HiveService.getUnlockDurationMinutes().toDouble();
    _notifications = HiveService.getNotificationsEnabled();
    _readingEnabled = HiveService.getReadingUnlockEnabled();
    _stepsEnabled = HiveService.getStepsUnlockEnabled();
    _stepGoal = HiveService.getStepGoal().toDouble();
    _pdfPath = HiveService.getReadingPdfPath();
    _emergencyLeft = HiveService.emergencyUnlocksRemaining();
    if (Platform.isAndroid) {
      _accessibilityOn =
          await BlockingService.instance.isAccessibilityEnabled();
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;
    final src = File(result.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(p.join(dir.path, 'sweatlock_book.pdf'));
    await src.copy(dest.path);
    await HiveService.setReadingPdfPath(dest.path);
    setState(() => _pdfPath = dest.path);
  }

  Future<void> _emergencyUnlock() async {
    final left = HiveService.emergencyUnlocksRemaining();
    if (left <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency unlock?'),
        content: Text('$left left today'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unlock')),
        ],
      ),
    );
    if (ok != true) return;
    final r = await EmergencyUnlockService.instance.unlockAll();
    setState(() => _emergencyLeft = r.remaining);
  }

  Future<void> _logout() async {
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

  Future<void> _apply() async {
    if (Platform.isIOS) await IosNudgeService.instance.startMonitoring();
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(t,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                )),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).cardColor,
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final blocked = context.watch<BlockingProvider>().blockedApps;
    final theme = context.watch<ThemeProvider>();
    final pdfName = _pdfPath == null ? 'No book' : p.basename(_pdfPath!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => theme.cycle(),
            icon: Icon(theme.icon, color: AppColors.primaryGreen),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          _section('Emergency'),
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Emergency unlock'),
              subtitle: Text('$_emergencyLeft left today'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _emergencyUnlock,
            ),
          ),
          _section('Blocking'),
          _card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Immediate'),
                  value: 'immediate',
                  groupValue: _blockMode,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _blockMode = v!);
                    await HiveService.setBlockMode(v ?? _blockMode);
                    await _apply();
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Timed free window'),
                  value: 'timed',
                  groupValue: _blockMode,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _blockMode = v!);
                    await HiveService.setBlockMode(v ?? _blockMode);
                    await _apply();
                  },
                ),
                if (_blockMode == 'timed') ...[
                  Text('Free minutes: ${_freeMinutes.round()}'),
                  Slider(
                    value: _freeMinutes,
                    min: 1,
                    max: 60,
                    activeColor: AppColors.primaryGreen,
                    onChanged: (v) => setState(() => _freeMinutes = v),
                    onChangeEnd: (v) async {
                      await HiveService.setFreeMinutes(v.round());
                      await _apply();
                    },
                  ),
                ],
                Text('Unlock duration: ${_unlockMinutes.round()} min'),
                Slider(
                  value: _unlockMinutes,
                  min: 5,
                  max: 120,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) => setState(() => _unlockMinutes = v),
                  onChangeEnd: (v) =>
                      HiveService.setUnlockDurationMinutes(v.round()),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Locked apps (${blocked.length})'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SelectAppsScreen()),
                  ),
                ),
              ],
            ),
          ),
          _section('Discipline'),
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.schedule, color: AppColors.primaryGreen),
                  title: const Text('Focus schedule'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FocusScheduleScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.people_alt_outlined,
                      color: AppColors.primaryGreen),
                  title: const Text('Accountability partner'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AccountabilityScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.campaign_outlined,
                      color: AppColors.primaryGreen),
                  title: const Text('Public feed posts'),
                  subtitle: const Text('Wins & fails on SweatLock social'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PublicAccountabilityScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shield_outlined,
                      color: AppColors.primaryGreen),
                  title: const Text('Stay locked in'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UninstallGuideScreen()),
                  ),
                ),
              ],
            ),
          ),
          _section('Challenges'),
          _card(
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  children: supportedExercises.map((e) {
                    final sel = e == _exercise;
                    return ChoiceChip(
                      label: Text(e),
                      selected: sel,
                      selectedColor: AppColors.primaryGreen,
                      onSelected: (_) async {
                        setState(() => _exercise = e);
                        await HiveService.setDefaultExercise(e);
                      },
                    );
                  }).toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Steps unlock'),
                  value: _stepsEnabled,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _stepsEnabled = v);
                    await HiveService.setStepsUnlockEnabled(v);
                  },
                ),
                if (_stepsEnabled)
                  Slider(
                    value: _stepGoal,
                    min: 100,
                    max: 5000,
                    activeColor: AppColors.primaryGreen,
                    onChanged: (v) => setState(() => _stepGoal = v),
                    onChangeEnd: (v) => HiveService.setStepGoal(v.round()),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reading + quiz'),
                  value: _readingEnabled,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _readingEnabled = v);
                    await HiveService.setReadingUnlockEnabled(v);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Book: $pdfName'),
                  trailing: TextButton(
                      onPressed: _pickPdf, child: const Text('Upload')),
                ),
              ],
            ),
          ),
          _section('Permissions'),
          _card(
            child: Column(
              children: [
                if (Platform.isAndroid)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Accessibility'),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications'),
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
          _section('About'),
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rate SweatLock'),
                  onTap: () async {
                    final r = InAppReview.instance;
                    if (await r.isAvailable()) {
                      await r.requestReview();
                    } else {
                      await r.openStoreListing();
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Log out'),
                  textColor: AppColors.red,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
