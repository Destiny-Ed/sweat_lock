import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/focus_schedule.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

class FocusScheduleScreen extends StatefulWidget {
  const FocusScheduleScreen({super.key});

  @override
  State<FocusScheduleScreen> createState() => _FocusScheduleScreenState();
}

class _FocusScheduleScreenState extends State<FocusScheduleScreen> {
  late FocusSchedule _s;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _s = HiveService.getFocusSchedule();
  }

  Future<void> _persist() async {
    await HiveService.setFocusSchedule(_s);
    // Always re-read from Hive so UI matches what was actually stored
    _reload();
    if (mounted) setState(() {});

    if (Platform.isIOS) {
      await IosNudgeService.instance.startMonitoring();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _s.enabled
              ? 'Saved · ${_s.timeRangeLabel}${_s.isActiveAt(DateTime.now()) ? ' · active now' : ''}'
              : 'Focus schedule off',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: isStart ? _s.startHour : _s.endHour,
      minute: isStart ? _s.startMinute : _s.endMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryGreen,
                  onPrimary: Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _s = isStart
          ? _s.copyWith(startHour: picked.hour, startMinute: picked.minute)
          : _s.copyWith(endHour: picked.hour, endMinute: picked.minute);
    });
    await _persist();
  }

  void _toggleDay(int day) {
    final days = List<int>.from(_s.weekdays);
    if (days.contains(day)) {
      if (days.length == 1) return;
      days.remove(day);
    } else {
      days.add(day);
      days.sort();
    }
    setState(() => _s = _s.copyWith(weekdays: days));
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    const labels = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onNow = _s.enabled && _s.isActiveAt(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Focus schedule')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.12 : 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'During this window, locked apps hard-lock immediately — '
              'no free scrolling, even if Timed mode is on.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('Enable focus schedule'),
              subtitle: Text(
                onNow ? 'Active right now' : (_s.enabled ? _s.timeRangeLabel : 'Off'),
              ),
              value: _s.enabled,
              activeThumbColor: Colors.black,
              activeTrackColor: AppColors.primaryGreen,
              onChanged: (v) {
                setState(() => _s = _s.copyWith(enabled: v));
                _persist();
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Days', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.entries.map((e) {
              final on = _s.weekdays.contains(e.key);
              return GestureDetector(
                onTap: () => _toggleDay(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on
                        ? AppColors.primaryGreen
                        : Theme.of(context).cardColor,
                    border: Border.all(
                      color: on
                          ? AppColors.primaryGreen
                          : (isDark ? Colors.white24 : Colors.black12),
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: on
                          ? Colors.black
                          : Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text('Hours', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _timeCard(
                  context,
                  label: 'Starts',
                  value:
                      '${_s.startHour.toString().padLeft(2, '0')}:${_s.startMinute.toString().padLeft(2, '0')}',
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeCard(
                  context,
                  label: 'Ends',
                  value:
                      '${_s.endHour.toString().padLeft(2, '0')}:${_s.endMinute.toString().padLeft(2, '0')}',
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          if (_s.enabled) ...[
            const SizedBox(height: 20),
            Text(
              onNow
                  ? '● Focus is ON now · ${_s.label}'
                  : '○ Next window · ${_s.label}',
              style: TextStyle(
                color: onNow ? AppColors.primaryGreen : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeCard(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  )),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
