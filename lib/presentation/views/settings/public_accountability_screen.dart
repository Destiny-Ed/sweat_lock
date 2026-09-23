import 'package:flutter/material.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';

/// Opt-in public posts (wins / wins+fails) for brand or personal feed.
class PublicAccountabilityScreen extends StatefulWidget {
  const PublicAccountabilityScreen({super.key});

  @override
  State<PublicAccountabilityScreen> createState() =>
      _PublicAccountabilityScreenState();
}

class _PublicAccountabilityScreenState extends State<PublicAccountabilityScreen> {
  late String _mode;
  late String _displayName;
  late bool _showAppNames;
  late bool _promptShare;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mode = HiveService.getPublicAccountabilityMode();
    _displayName = HiveService.getPublicDisplayName();
    _showAppNames = HiveService.getPublicShowAppNames();
    _promptShare = HiveService.getPromptShareOnWin();
    _nameCtrl.text = _displayName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _setMode(String mode) async {
    if (mode != 'off' && _mode == 'off') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Go public?'),
          content: const Text(
            'SweatLock may share short win (and optionally fail) updates '
            'on the SweatLock page or via your share sheet. '
            'You can turn this off anytime. No phone number is posted.',
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
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await HiveService.setPublicAccountabilityMode(mode);
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public accountability')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'When you unlock an app — or burn the free window without a '
            'workout — SweatLock can post a short update. Best for promotion '
            'and social pressure.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 20),
          Text('Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  )),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Off'),
            subtitle: const Text('Default — nothing shared'),
            value: 'off',
            groupValue: _mode,
            activeColor: AppColors.primaryGreen,
            onChanged: (v) => _setMode(v!),
          ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Wins only'),
            subtitle: const Text('Celebrate unlocks (recommended start)'),
            value: 'wins_only',
            groupValue: _mode,
            activeColor: AppColors.primaryGreen,
            onChanged: (v) => _setMode(v!),
          ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Wins + fails'),
            subtitle: const Text(
              'Also post when free time runs out without a challenge',
            ),
            value: 'wins_and_fails',
            groupValue: _mode,
            activeColor: AppColors.primaryGreen,
            onChanged: (v) => _setMode(v!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display name on posts',
              hintText: 'First name or alias',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) async {
              await HiveService.setPublicDisplayName(v.trim());
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include app names'),
            subtitle: const Text('e.g. “TikTok” vs “a locked app”'),
            value: _showAppNames,
            activeColor: AppColors.primaryGreen,
            onChanged: (v) async {
              setState(() => _showAppNames = v);
              await HiveService.setPublicShowAppNames(v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Share sheet after each win'),
            subtitle: const Text('Until the brand auto-poster is live'),
            value: _promptShare,
            activeColor: AppColors.primaryGreen,
            onChanged: (v) async {
              setState(() => _promptShare = v);
              await HiveService.setPromptShareOnWin(v);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Example win:\n'
              '🔥 Alex just earned TikTok with 25 push-ups. '
              'Screen time earned, not stolen. #SweatLock\n\n'
              'Example fail:\n'
              '⏳ Alex let the free window run out on Instagram — still locked. '
              'Earn it or leave it. #SweatLock',
              style: TextStyle(height: 1.4, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
