import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';

/// Scaffold for social accountability — local codes today, backend later.
/// See docs/SOCIAL_ACCOUNTABILITY.md
class AccountabilityScreen extends StatefulWidget {
  const AccountabilityScreen({super.key});

  @override
  State<AccountabilityScreen> createState() => _AccountabilityScreenState();
}

class _AccountabilityScreenState extends State<AccountabilityScreen> {
  late String _myCode;
  final _linkCtrl = TextEditingController();
  String? _linked;

  @override
  void initState() {
    super.initState();
    _myCode = HiveService.getOrCreatePartnerCode();
    _linked = HiveService.getLinkedPartnerCode();
    if (_linked != null) _linkCtrl.text = _linked!;
  }

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveLink() async {
    final code = _linkCtrl.text.trim().toUpperCase();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid partner code')),
      );
      return;
    }
    if (code == _myCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can’t link to yourself')),
      );
      return;
    }
    await HiveService.setLinkedPartnerCode(code);
    setState(() => _linked = code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Partner saved locally. Live sync & push arrive with the backend.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accountability partner')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Why this matters',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Solo blockers get deleted on a weak day. A partner makes '
            'emergency unlocks and quitting social — the same idea as '
            '“hold my password,” productized.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                const Text('Your invite code',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SelectableText(
                  _myCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _myCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy, color: AppColors.primaryGreen),
                  label: const Text('Copy code',
                      style: TextStyle(color: AppColors.primaryGreen)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Link a partner',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linkCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Their 6-letter code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_linked == null ? 'Save partner' : 'Update partner'),
            ),
          ),
          if (_linked != null) ...[
            const SizedBox(height: 8),
            Text(
              'Linked to $_linked (local only for now)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
          const SizedBox(height: 28),
          const Text(
            'Coming with the backend',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('• Partner notified on emergency unlock'),
          const Text('• Optional partner approval for emergency unlock'),
          const Text('• Shared streak & focus-schedule compliance'),
          const Text('• Alert if SweatLock is uninstalled (best-effort)'),
        ],
      ),
    );
  }
}
