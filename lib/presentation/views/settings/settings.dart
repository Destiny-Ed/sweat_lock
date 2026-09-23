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
import 'package:sweat_lock/presentation/views/settings/uninstall_guide_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/emergency_unlock_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';
import 'package:sweat_lock/services/music_service.dart';

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
  late double _warningMinutes;
  late double _unlockMinutes;
  late bool _notifications;
  late bool _preventUninstall;
  late bool _readingEnabled;
  late bool _stepsEnabled;
  late double _stepGoal;
  late bool _preferYoutube;
  late List<String> _genres;
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
    _warningMinutes = HiveService.getWarningMinutes().toDouble();
    _unlockMinutes = HiveService.getUnlockDurationMinutes().toDouble();
    _notifications = HiveService.getNotificationsEnabled();
    _preventUninstall = HiveService.getPreventUninstall();
    _readingEnabled = HiveService.getReadingUnlockEnabled();
    _stepsEnabled = HiveService.getStepsUnlockEnabled();
    _stepGoal = HiveService.getStepGoal().toDouble();
    _preferYoutube = HiveService.getPreferYoutubeMusic();
    _genres = List<String>.from(HiveService.getMusicGenres());
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
    _toast('Book saved');
  }

  Future<void> _rateApp() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  }

  Future<void> _emergencyUnlock() async {
    final left = HiveService.emergencyUnlocksRemaining();
    if (left <= 0) {
      _toast('No emergency unlocks left today');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.lightGreen : Theme.of(ctx).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Emergency unlock?'),
          content: Text(
            'Unlocks all locked apps for $emergencyUnlockDurationMinutes minutes without a challenge.\n\n'
            'You have $left use(s) left today.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unlock now'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final result = await EmergencyUnlockService.instance.unlockAll();
    setState(() => _emergencyLeft = result.remaining);
    _toast(result.message);
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
    _toast('Preferences applied');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocked = context.watch<BlockingProvider>().blockedApps;
    final theme = context.watch<ThemeProvider>();
    final pdfName =
        _pdfPath == null ? 'No book uploaded' : p.basename(_pdfPath!);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStepsDefault = _exercise == 'steps';

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
          _section('Appearance'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _themeChip(theme, ThemeMode.system, 'System',
                        Icons.brightness_auto_rounded),
                    const SizedBox(width: 8),
                    _themeChip(theme, ThemeMode.light, 'Light',
                        Icons.light_mode_rounded),
                    const SizedBox(width: 8),
                    _themeChip(theme, ThemeMode.dark, 'Dark',
                        Icons.dark_mode_rounded),
                  ],
                ),
              ],
            ),
          ),
          _section('Emergency'),
          _card(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _emergencyUnlock,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.emergency, color: AppColors.red),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Emergency unlock',
                                style: Theme.of(context).textTheme.titleLarge),
                            Text(
                              '$_emergencyLeft left today · $emergencyUnlockDurationMinutes min unlock',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: isDark ? Colors.white54 : Colors.black45),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _section('Blocking'),
          _card(
            child: Column(
              children: [
                _modeTile('Immediate', 'Lock as soon as the app opens', 'immediate'),
                _modeTile('Timed free window', 'Use for a few minutes, then lock',
                    'timed'),
                if (_blockMode == 'timed') ...[
                  const Divider(height: 20),
                  _sliderRow(
                    'Free minutes',
                    _freeMinutes,
                    1,
                    60,
                    (v) => setState(() => _freeMinutes = v),
                    (v) async {
                      await HiveService.setFreeMinutes(v.round());
                      await _applyMonitoringPrefs();
                    },
                  ),
                  _sliderRow(
                    'Warn before lock',
                    _warningMinutes,
                    1,
                    15,
                    (v) => setState(() => _warningMinutes = v),
                    (v) async {
                      await HiveService.setWarningMinutes(v.round());
                      await _applyMonitoringPrefs();
                    },
                  ),
                ],
                const Divider(height: 20),
                _sliderRow(
                  'Unlock duration (min)',
                  _unlockMinutes,
                  5,
                  120,
                  (v) => setState(() => _unlockMinutes = v),
                  (v) => HiveService.setUnlockDurationMinutes(v.round()),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Locked apps (${blocked.length})'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SelectAppsScreen()),
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
                  subtitle: const Text('Hard-lock social during work hours'),
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
                  subtitle:
                      const Text('Invite a friend — local codes for now'),
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
                  leading: const Icon(Icons.shield_outlined,
                      color: AppColors.primaryGreen),
                  title: const Text('Stay locked in'),
                  subtitle:
                      const Text('Uninstall friction guide (iOS & Android)'),
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
          _section('Unlock challenges'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Default challenge type',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: supportedExercises.map((e) {
                    final sel = e == _exercise;
                    return ChoiceChip(
                      label: Text(e == 'steps' ? 'steps (walk)' : e),
                      selected: sel,
                      selectedColor: AppColors.primaryGreen,
                      labelStyle: TextStyle(
                        color: sel
                            ? Colors.black
                            : Theme.of(context).textTheme.titleSmall?.color,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) async {
                        setState(() => _exercise = e);
                        await HiveService.setDefaultExercise(e);
                        if (e == 'steps') {
                          await HiveService.setStepsUnlockEnabled(true);
                          setState(() => _stepsEnabled = true);
                        }
                      },
                    );
                  }).toList(),
                ),
                if (!isStepsDefault)
                  _sliderRow(
                    'Reps per session',
                    _reps,
                    5,
                    100,
                    (v) => setState(() => _reps = v),
                    (v) => HiveService.setDefaultReps(v.round()),
                  ),
              ],
            ),
          ),
          _section('Walk to unlock'),
          _card(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow steps instead of workout'),
                  value: _stepsEnabled,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _stepsEnabled = v);
                    await HiveService.setStepsUnlockEnabled(v);
                  },
                ),
                if (_stepsEnabled)
                  _sliderRow(
                    'Step goal',
                    _stepGoal,
                    100,
                    5000,
                    (v) => setState(() => _stepGoal = v),
                    (v) => HiveService.setStepGoal(v.round()),
                  ),
              ],
            ),
          ),
          _section('Unlock by reading'),
          _card(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow reading + quiz'),
                  subtitle: Text(
                    'Read $requiredReadingPages pages (≥${readingDwellSecondsPerPage}s each), then quiz',
                  ),
                  value: _readingEnabled,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _readingEnabled = v);
                    await HiveService.setReadingUnlockEnabled(v);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf,
                      color: AppColors.primaryGreen),
                  title: const Text('Book PDF'),
                  subtitle: Text(pdfName),
                  trailing: TextButton(
                    onPressed: _pickPdf,
                    child: Text(_pdfPath == null ? 'Upload' : 'Replace'),
                  ),
                ),
              ],
            ),
          ),
          _section('Permissions & security'),
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
                      if (on) await BlockingService.instance.startListening();
                    },
                  ),
                if (Platform.isIOS)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Screen Time'),
                    trailing: TextButton(
                      onPressed: () async {
                        final ok = await IosNudgeService.instance
                            .requestAuthorization();
                        _toast(ok ? 'Approved' : 'Denied or pending');
                      },
                      child: const Text('Authorize'),
                    ),
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
                  leading: const Icon(Icons.star_rounded,
                      color: AppColors.primaryGreen),
                  title: const Text('Rate SweatLock'),
                  onTap: _rateApp,
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

  Widget _themeChip(
    ThemeProvider theme,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final sel = theme.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => theme.setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: sel
                ? AppColors.primaryGreen.withValues(alpha: 0.25)
                : Theme.of(context).secondaryHeaderColor.withValues(alpha: 0.4),
            border: Border.all(
              color: sel ? AppColors.primaryGreen : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: sel ? AppColors.primaryGreen : null),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTile(String title, String subtitle, String value) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: _blockMode,
      activeColor: AppColors.primaryGreen,
      onChanged: (v) async {
        if (v == null) return;
        setState(() => _blockMode = v);
        await HiveService.setBlockMode(v);
        await _applyMonitoringPrefs();
      },
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    ValueChanged<double> onEnd,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label)),
            Text('${value.round()}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).round() > 100 ? 50 : (max - min).round(),
          activeColor: AppColors.primaryGreen,
          onChanged: onChanged,
          onChangeEnd: onEnd,
        ),
      ],
    );
  }
}
