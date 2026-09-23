import 'package:flutter/material.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/data/models/focus_schedule.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';
import 'dart:io';

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
    _s = HiveService.getFocusSchedule();
  }

  Future<void> _persist() async {
    await HiveService.setFocusSchedule(_s);
    if (Platform.isIOS) {
      // Re-apply monitoring so timed vs immediate matches schedule when app is open
      await IosNudgeService.instance.startMonitoring();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _s.enabled
                ? 'Focus window on: ${_s.label}'
                : 'Focus schedule off',
          ),
        ),
      );
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = TimeOfDay(
      hour: isStart ? _s.startHour : _s.endHour,
      minute: isStart ? _s.startMinute : _s.endMinute,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
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

    return Scaffold(
      appBar: AppBar(title: const Text('Focus schedule')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'During this window, locked apps are treated as immediate lock — '
            'no free scrolling, even if Timed mode is on elsewhere.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable focus schedule'),
            value: _s.enabled,
            activeColor: AppColors.primaryGreen,
            onChanged: (v) {
              setState(() => _s = _s.copyWith(enabled: v));
              _persist();
            },
          ),
          const SizedBox(height: 8),
          Text('Days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.entries.map((e) {
              final on = _s.weekdays.contains(e.key);
              return GestureDetector(
                onTap: () => _toggleDay(e.key),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: on
                      ? AppColors.primaryGreen
                      : Theme.of(context).cardColor,
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: on ? Colors.black : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Starts'),
            trailing: Text(
              '${_s.startHour.toString().padLeft(2, '0')}:'
              '${_s.startMinute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            onTap: () => _pickTime(isStart: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ends'),
            trailing: Text(
              '${_s.endHour.toString().padLeft(2, '0')}:'
              '${_s.endMinute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            onTap: () => _pickTime(isStart: false),
          ),
          if (_s.enabled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Active window: ${_s.label}'
                '${_s.isActiveAt(DateTime.now()) ? ' · ON NOW' : ''}',
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }
}
