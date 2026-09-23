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
import 'package:sweat_lock/data/models/user_progress.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/blocking/select_apps_screen.dart';
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
  late bool _readingEnabled;
  String? _pdfPath;
  bool _accessibilityOn = false;

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
    _readingEnabled = HiveService.getReadingUnlockEnabled();
    _pdfPath = HiveService.getReadingPdfPath();

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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book saved — use it to unlock')),
      );
    }
  }

  Future<void> _rateApp() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
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

    final mins = HiveService.getUnlockDurationMinutes();
    if (Platform.isAndroid) {
      BlockingService.instance.grantCurrentUnlock(minutes: mins);
    }
    if (Platform.isIOS) {
      await IosNudgeService.instance.onWorkoutCompleted(unlockMinutes: mins);
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
          'Clears locked apps and progress on this device.',
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
        const SnackBar(content: Text('Preferences applied')),
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

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    final blocked = context.watch<BlockingProvider>().blockedApps;
    final pdfName =
        _pdfPath == null ? 'No book uploaded' : p.basename(_pdfPath!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        children: [
          _sectionTitle('Blocking'),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Immediate'),
                  subtitle: const Text('Lock as soon as the app is used'),
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
                    'Screen Time minutes of use, then lock',
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
                  _sliderRow(
                    'Free minutes (Screen Time)',
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
                    'Warn before lock (min)',
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
                const Divider(),
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
                    MaterialPageRoute(
                      builder: (_) => const SelectAppsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _sectionTitle('Unlock by reading'),
          _card(
            Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow reading instead of workout'),
                  subtitle: Text(
                    'Read $requiredReadingPages unique pages to unlock',
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
          _sectionTitle('Exercise defaults'),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sliderRow(
                  'Reps per session',
                  _reps,
                  5,
                  100,
                  (v) => setState(() => _reps = v),
                  (v) => HiveService.setDefaultReps(v.round()),
                ),
                const SizedBox(height: 8),
                Text('Default exercise',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
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
              ],
            ),
          ),
          _sectionTitle('Permissions & security'),
          _card(
            Column(
              children: [
                if (Platform.isAndroid)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Accessibility'),
                    subtitle: Text(
                      _accessibilityOn ? 'Enabled' : 'Required for blocking',
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
                    title: const Text('Screen Time'),
                    subtitle: const Text('Family Controls authorization'),
                    trailing: TextButton(
                      onPressed: () async {
                        final ok = await IosNudgeService.instance
                            .requestAuthorization();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? 'Approved' : 'Denied or pending',
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
                  value: _notifications,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _notifications = v);
                    await HiveService.setNotificationsEnabled(v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Discourage uninstall'),
                  subtitle: Text(
                    Platform.isIOS
                        ? 'Not enforceable without MDM'
                        : 'Preference only',
                  ),
                  value: _preventUninstall,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (v) async {
                    setState(() => _preventUninstall = v);
                    await HiveService.setPreventUninstall(v);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Emergency unlock'),
                  trailing: Text('$_emergencyLeft left'),
                  onTap: _useEmergencyUnlock,
                ),
              ],
            ),
          ),
          _sectionTitle('About'),
          _card(
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Rate SweatLock'),
                  subtitle: const Text('Share feedback on the store'),
                  leading: const Icon(Icons.star_rounded,
                      color: AppColors.primaryGreen),
                  onTap: _rateApp,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Version'),
                  trailing: const Text('1.0.0'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Log out'),
                  textColor: Colors.redAccent,
                  onTap: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
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
            Text('${value.round()}'),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).round(),
          activeColor: AppColors.primaryGreen,
          onChanged: onChanged,
          onChangeEnd: onEnd,
        ),
      ],
    );
  }
}
