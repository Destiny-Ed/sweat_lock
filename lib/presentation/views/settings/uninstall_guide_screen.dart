import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sweat_lock/core/theme.dart';

/// Honest limits: OS will always allow uninstall. Guide raises friction + awareness.
class UninstallGuideScreen extends StatelessWidget {
  const UninstallGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isIos = Platform.isIOS;

    return Scaffold(
      appBar: AppBar(title: const Text('Stay locked in')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'No consumer app can fully prevent uninstall without MDM or '
              'device supervision. Use these steps to make quitting harder '
              'on a weak day.',
              style: TextStyle(height: 1.45),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isIos ? 'iPhone / iPad' : 'Android',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          if (isIos) ..._iosSteps(context) else ..._androidSteps(context),
          const SizedBox(height: 28),
          Text(
            'Extra friction',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          _step(
            context,
            '1',
            'Accountability partner',
            'Invite a friend (Settings → Partner). Quitting feels social, not private.',
          ),
          _step(
            context,
            '2',
            'Focus schedule',
            'Hard-block social during work hours so “I’ll just uninstall” is still painful mid-day.',
          ),
          _step(
            context,
            '3',
            'Screen Time / Digital Wellbeing passcode',
            isIos
                ? 'Settings → Screen Time → Use Screen Time Passcode. '
                    'Don’t store it in Notes on this phone.'
                : 'Digital Wellbeing → set a PIN for app timers if available on your OEM.',
          ),
        ],
      ),
    );
  }

  List<Widget> _iosSteps(BuildContext context) => [
        _step(
          context,
          'A',
          'Keep Screen Time authorized',
          'SweatLock needs Family Controls. Don’t revoke it when frustrated — wait out the urge.',
        ),
        _step(
          context,
          'B',
          'Screen Time passcode',
          'Settings → Screen Time → turn on a passcode separate from your device PIN. Ask a partner to set it.',
        ),
        _step(
          context,
          'C',
          'App limits backup',
          'Settings → Screen Time → App Limits for the same social apps as a second line of defense.',
        ),
        _step(
          context,
          'D',
          'Avoid “Delete App” path',
          'Long-press → Remove App is still possible. Combine with partner + schedule.',
        ),
      ];

  List<Widget> _androidSteps(BuildContext context) => [
        _step(
          context,
          'A',
          'Keep Accessibility on',
          'SweatLock blocking needs Accessibility. Turning it off disables locks.',
        ),
        _step(
          context,
          'B',
          'Device admin / work profile (advanced)',
          'Some OEMs allow restricted profiles. Full uninstall prevention needs device owner / MDM.',
        ),
        _step(
          context,
          'C',
          'Digital Wellbeing',
          'Set app timers for the same apps as a backup if SweatLock is disabled.',
        ),
        _step(
          context,
          'D',
          'Hide from launcher (optional)',
          'Some launchers can hide apps — security through friction, not certainty.',
        ),
      ];

  Widget _step(
    BuildContext context,
    String n,
    String title,
    String body,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
            child: Text(
              n,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleSmall?.color,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
