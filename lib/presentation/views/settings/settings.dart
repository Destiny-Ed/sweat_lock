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
import 'package:sweat_lock/data/models/focus_schedule.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/providers/theme_provider.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/blocking/select_apps_screen.dart';
import 'package:sweat_lock/presentation/views/settings/focus_schedule_screen.dart';
import 'package:sweat_lock/presentation/views/settings/uninstall_guide_screen.dart';
// v1.1 — partner / public feed (keep screens in repo, hide from settings for launch)
// import 'package:sweat_lock/presentation/views/settings/accountability_screen.dart';
// import 'package:sweat_lock/presentation/views/settings/public_accountability_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/emergency_unlock_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';
import 'package:sweat_lock/services/schedule_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _exercise;
  late String _blockMode;
  late double _freeMinutes;
  late double _warningMinutes;
  late double _unlockMinutes;
  late bool _notifications;
  late bool _readingEnabled;
  late bool _stepsEnabled;
  late double _stepGoal;
  late double _reps;
  String? _pdfPath;
  bool _accessibilityOn = false;
  int _emergencyLeft = 0;
  FocusSchedule _focus = const FocusSchedule();

  static const _exerciseMeta = <String, (IconData, String)>{
    'push-ups': (Icons.fitness_center_rounded, 'Arms & chest'),
    'squats': (Icons.accessibility_new_rounded, 'Legs'),
    'sit-ups': (Icons.self_improvement_rounded, 'Core'),
    'jumping jacks': (Icons.directions_run_rounded, 'Cardio'),
    'steps': (Icons.directions_walk_rounded, 'Walk to unlock'),
  };

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
    _warningMinutes = HiveService.getWarningMinutes().toDouble();
    _unlockMinutes = HiveService.getUnlockDurationMinutes().toDouble();
    _notifications = HiveService.getNotificationsEnabled();
    _readingEnabled = HiveService.getReadingUnlockEnabled();
    _stepsEnabled = HiveService.getStepsUnlockEnabled();
    _stepGoal = HiveService.getStepGoal().toDouble();
    _pdfPath = HiveService.getReadingPdfPath();
    _emergencyLeft = HiveService.emergencyUnlocksRemaining();
    _focus = HiveService.getFocusSchedule();
    if (Platform.isAndroid) {
      _accessibilityOn =
          await BlockingService.instance.isAccessibilityEnabled();
    }
    if (mounted) setState(() {});
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _border => _isDark
      ? AppColors.primaryGreen.withValues(alpha: 0.18)
      : Colors.black.withValues(alpha: 0.06);

  Color get _muted =>
      _isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black54;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    final src = File(result.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(p.join(dir.path, 'sweatlock_book.pdf'));
    await src.copy(dest.path);
    await HiveService.setReadingPdfPath(dest.path);
    setState(() => _pdfPath = dest.path);
  }

  Future<void> _apply() async {
    if (Platform.isIOS) await IosNudgeService.instance.startMonitoring();
  }

  Future<void> _emergencyUnlock() async {
    final left = HiveService.emergencyUnlocksRemaining();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EmergencyUnlockSheet(remaining: left),
    );
    if (ok != true) return;
    if (left <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emergency unlocks left today')),
      );
      return;
    }
    final r = await EmergencyUnlockService.instance.unlockAll();
    setState(() => _emergencyLeft = r.remaining);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Clears locked apps and progress on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out')),
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

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor,
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.28 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _modeCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _blockMode == value;
    return GestureDetector(
      onTap: () async {
        setState(() => _blockMode = value);
        await HiveService.setBlockMode(value);
        await _apply();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? AppColors.primaryGreen.withValues(alpha: _isDark ? 0.18 : 0.2)
              : (_isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          border: Border.all(
            color: selected
                ? AppColors.primaryGreen
                : _border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? AppColors.primaryGreen
                    : AppColors.primaryGreen.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.black : AppColors.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.primaryGreen : _muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderBlock({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onEnd,
    String? unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${value.round()}${unit ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryGreen,
            inactiveTrackColor:
                AppColors.primaryGreen.withValues(alpha: 0.2),
            thumbColor: AppColors.primaryGreen,
            overlayColor: AppColors.primaryGreen.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round().clamp(1, 100),
            onChanged: onChanged,
            onChangeEnd: onEnd,
          ),
        ),
      ],
    );
  }

  Widget _exerciseTile(String e) {
    final sel = e == _exercise;
    final meta = _exerciseMeta[e] ?? (Icons.fitness_center, '');
    return GestureDetector(
      onTap: () async {
        setState(() => _exercise = e);
        await HiveService.setDefaultExercise(e);
        if (e == 'steps') {
          await HiveService.setStepsUnlockEnabled(true);
          setState(() => _stepsEnabled = true);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: (MediaQuery.of(context).size.width - 64) / 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: sel
              ? AppColors.primaryGreen.withValues(alpha: _isDark ? 0.22 : 0.25)
              : (_isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03)),
          border: Border.all(
            color: sel ? AppColors.primaryGreen : _border,
            width: sel ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              meta.$1,
              color: sel ? AppColors.primaryGreen : _muted,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              e,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: sel
                    ? (_isDark ? Colors.white : Colors.black)
                    : Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            if (meta.$2.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(meta.$2, style: TextStyle(fontSize: 11, color: _muted)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = context.watch<BlockingProvider>().blockedApps;
    final theme = context.watch<ThemeProvider>();
    final pdfName = _pdfPath == null ? 'No book uploaded' : p.basename(_pdfPath!);
    final focusOn = ScheduleService.instance.isInFocusWindow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Theme: ${theme.label}',
            onPressed: () => theme.cycle(),
            icon: Icon(theme.icon, color: AppColors.primaryGreen),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          // —— Emergency ——
          _section('Emergency'),
          _card(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _emergencyUnlock,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.emergency_rounded,
                            color: AppColors.red),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Emergency unlock',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              '$_emergencyLeft left · $emergencyUnlockDurationMinutes min free',
                              style: TextStyle(fontSize: 12, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _muted),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // —— Blocking ——
          _section('Blocking'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modeCard(
                  value: 'immediate',
                  title: 'Immediate',
                  subtitle: 'Lock the moment a selected app opens',
                  icon: Icons.bolt_rounded,
                ),
                _modeCard(
                  value: 'timed',
                  title: 'Timed free window',
                  subtitle: 'Use for a few minutes, then lock',
                  icon: Icons.timer_outlined,
                ),
                if (_blockMode == 'timed') ...[
                  const SizedBox(height: 4),
                  _sliderBlock(
                    label: 'Free minutes',
                    value: _freeMinutes,
                    min: 1,
                    max: 60,
                    unit: 'm',
                    onChanged: (v) => setState(() => _freeMinutes = v),
                    onEnd: (v) async {
                      await HiveService.setFreeMinutes(v.round());
                      await _apply();
                    },
                  ),
                  _sliderBlock(
                    label: 'Warn before lock',
                    value: _warningMinutes,
                    min: 1,
                    max: 15,
                    unit: 'm',
                    onChanged: (v) => setState(() => _warningMinutes = v),
                    onEnd: (v) async {
                      await HiveService.setWarningMinutes(v.round());
                      await _apply();
                    },
                  ),
                ],
                const Divider(height: 24),
                _sliderBlock(
                  label: 'Unlock duration after workout',
                  value: _unlockMinutes,
                  min: 5,
                  max: 120,
                  unit: 'm',
                  onChanged: (v) => setState(() => _unlockMinutes = v),
                  onEnd: (v) =>
                      HiveService.setUnlockDurationMinutes(v.round()),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.apps_rounded,
                        color: AppColors.primaryGreen, size: 20),
                  ),
                  title: Text('Locked apps (${blocked.length})'),
                  subtitle: Text(
                    blocked.isEmpty ? 'None selected' : 'Tap to manage',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  trailing: Icon(Icons.chevron_right, color: _muted),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SelectAppsScreen()),
                  ).then((_) => _load()),
                ),
              ],
            ),
          ),

          // —— Focus (v1) ——
          _section('Focus'),
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (focusOn ? AppColors.primaryGreen : _muted)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: focusOn ? AppColors.primaryGreen : _muted,
                      size: 20,
                    ),
                  ),
                  title: const Text('Focus schedule'),
                  subtitle: Text(
                    !_focus.enabled
                        ? 'Off — set work hours hard-lock'
                        : focusOn
                            ? 'ON NOW · ${_focus.timeRangeLabel}'
                            : _focus.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: focusOn ? AppColors.primaryGreen : _muted,
                      fontWeight: focusOn ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: _muted),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FocusScheduleScreen()),
                    );
                    _load();
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.primaryGreen, size: 20),
                  ),
                  title: const Text('Stay locked in'),
                  subtitle: Text(
                    'Tips to resist uninstall (iOS & Android)',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  trailing: Icon(Icons.chevron_right, color: _muted),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UninstallGuideScreen()),
                  ),
                ),
                // —— v1.1 (commented for launch) ——
                // const Divider(),
                // ListTile( title: Text('Accountability partner'), ... AccountabilityScreen ),
                // ListTile( title: Text('Public feed posts'), ... PublicAccountabilityScreen ),
              ],
            ),
          ),

          // —— Challenges ——
          _section('Challenges'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default unlock workout',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'What users do first when an app is locked',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      supportedExercises.map((e) => _exerciseTile(e)).toList(),
                ),
                if (_exercise != 'steps') ...[
                  const SizedBox(height: 16),
                  _sliderBlock(
                    label: 'Reps required',
                    value: _reps,
                    min: 5,
                    max: 100,
                    onChanged: (v) => setState(() => _reps = v),
                    onEnd: (v) => HiveService.setDefaultReps(v.round()),
                  ),
                ],
                const Divider(height: 28),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow steps unlock'),
                  subtitle: Text('Walk to unlock as an alternative',
                      style: TextStyle(fontSize: 12, color: _muted)),
                  value: _stepsEnabled,
                  activeThumbColor: Colors.black,
                  activeTrackColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _stepsEnabled = v);
                    await HiveService.setStepsUnlockEnabled(v);
                  },
                ),
                if (_stepsEnabled)
                  _sliderBlock(
                    label: 'Step goal',
                    value: _stepGoal,
                    min: 100,
                    max: 5000,
                    onChanged: (v) => setState(() => _stepGoal = v),
                    onEnd: (v) => HiveService.setStepGoal(v.round()),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow reading + quiz'),
                  subtitle: Text(
                    '$requiredReadingPages pages · pass quiz to unlock',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  value: _readingEnabled,
                  activeThumbColor: Colors.black,
                  activeTrackColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _readingEnabled = v);
                    await HiveService.setReadingUnlockEnabled(v);
                  },
                ),
                if (_readingEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.primaryGreen),
                    title: const Text('Book PDF'),
                    subtitle: Text(pdfName,
                        style: TextStyle(fontSize: 12, color: _muted)),
                    trailing: TextButton(
                      onPressed: _pickPdf,
                      child: Text(_pdfPath == null ? 'Upload' : 'Replace'),
                    ),
                  ),
              ],
            ),
          ),

          // —— Permissions ——
          _section('Permissions'),
          _card(
            child: Column(
              children: [
                if (Platform.isAndroid)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Accessibility'),
                    subtitle: Text(
                      _accessibilityOn
                          ? 'Enabled — blocking active'
                          : 'Required for Android blocking',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                    value: _accessibilityOn,
                    activeThumbColor: Colors.black,
                    activeTrackColor: AppColors.primaryGreen,
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
                    title: const Text('Screen Time'),
                    subtitle: Text('Family Controls authorization',
                        style: TextStyle(fontSize: 12, color: _muted)),
                    trailing: TextButton(
                      onPressed: () async {
                        final ok = await IosNudgeService.instance
                            .requestAuthorization();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                ok ? 'Authorized' : 'Denied or pending'),
                          ),
                        );
                      },
                      child: const Text('Authorize'),
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications'),
                  value: _notifications,
                  activeThumbColor: Colors.black,
                  activeTrackColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _notifications = v);
                    await HiveService.setNotificationsEnabled(v);
                  },
                ),
              ],
            ),
          ),

          // —— About ——
          _section('About'),
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_rounded,
                      color: AppColors.primaryGreen),
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
                const Divider(),
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

/// Beautiful emergency unlock bottom sheet for v1.
class _EmergencyUnlockSheet extends StatelessWidget {
  final int remaining;

  const _EmergencyUnlockSheet({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUse = remaining > 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.lightGreen : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emergency_rounded,
                color: AppColors.red, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Emergency unlock',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Skips the workout once and unlocks every locked app for '
            '$emergencyUnlockDurationMinutes minutes. Use only when you '
            'truly need access — not as a daily bypass.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.12 : 0.15),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _infoRow(Icons.timer_outlined, 'Duration',
                    '$emergencyUnlockDurationMinutes minutes'),
                const SizedBox(height: 10),
                _infoRow(Icons.today_outlined, 'Uses left today',
                    canUse ? '$remaining of $emergencyUnlocksPerDay' : '0 — come back tomorrow'),
                const SizedBox(height: 10),
                _infoRow(Icons.apps_outlined, 'Scope', 'All locked apps'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canUse ? () => Navigator.pop(context, true) : null,
              style: FilledButton.styleFrom(
                backgroundColor: canUse ? AppColors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                canUse ? 'Unlock all apps now' : 'No uses left today',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
