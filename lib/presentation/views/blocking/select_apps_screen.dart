import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/views/blocking/ios_nudge_screen.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

class SelectAppsScreen extends StatefulWidget {
  const SelectAppsScreen({super.key});

  @override
  State<SelectAppsScreen> createState() => _SelectAppsScreenState();
}

class _SelectAppsScreenState extends State<SelectAppsScreen> {
  bool _iosLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BlockingProvider>();
      if (Platform.isAndroid) {
        vm.loadInstalledApps();
        vm.checkAccessibility();
      } else if (Platform.isIOS) {
        IosNudgeService.instance.loadSavedSelections();
        vm.loadBlockedApps();
      }
    });
  }

  Future<void> _handleIosSelect() async {
    setState(() => _iosLoading = true);
    final authorized = await IosNudgeService.instance.requestAuthorization();
    if (!authorized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Screen Time authorization denied or not approved yet. Check Settings → Screen Time.',
            ),
          ),
        );
      }
      setState(() => _iosLoading = false);
      return;
    }

    final apps = await IosNudgeService.instance.selectApps();
    if (mounted) {
      context.read<BlockingProvider>().loadBlockedApps();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apps.isEmpty
                ? 'No apps selected'
                : '${apps.length} apps selected for monitoring',
          ),
        ),
      );
    }
    setState(() => _iosLoading = false);
  }

  void _previewNudge(BlockingProvider vm) {
    final iosApps = vm.blockedApps.where((a) => a.bundleId.isNotEmpty).toList();
    final androidApps = vm.blockedApps;
    final sample = iosApps.isNotEmpty
        ? iosApps.first
        : (androidApps.isNotEmpty ? androidApps.first : null);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IosNudgeScreen(
          usageMinutes: 25,
          appName: sample?.appName ?? 'Instagram',
          bundleId: sample?.bundleId.isNotEmpty == true
              ? sample!.bundleId
              : sample?.packageName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Apps to Lock')),
      body: Consumer<BlockingProvider>(
        builder: (context, vm, _) {
          if (Platform.isIOS) {
            final monitored =
                vm.blockedApps.where((a) => a.bundleId.isNotEmpty).toList();

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryGreen),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'iOS Smart Nudge Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Select apps with Screen Time. After heavy usage, '
                          'SweatLock shows a workout nudge. Hard real-time blocking is not available on iOS.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _iosLoading ? null : _handleIosSelect,
                    icon: _iosLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.apps),
                    label: Text(
                      _iosLoading ? 'Opening…' : 'Select apps (Screen Time)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _previewNudge(vm),
                    icon: const Icon(Icons.preview),
                    label: Text(
                      monitored.isNotEmpty
                          ? 'Preview nudge (${monitored.first.appName})'
                          : 'Preview nudge screen',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Monitored apps (${monitored.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: monitored.isEmpty
                        ? const Center(
                            child: Text(
                              'No iOS apps selected yet.\nTap “Select apps (Screen Time)” above.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView(
                            children: monitored
                                .map(
                                  (a) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryGreen
                                          .withValues(alpha: 0.2),
                                      child: const Icon(
                                        Icons.phone_iphone,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    title: Text(a.appName),
                                    subtitle: Text(
                                      '${a.requiredReps} ${a.exerciseType}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () =>
                                          vm.removeBlockedApp(a.id),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            );
          }

          // Android
          return Column(
            children: [
              if (!vm.accessibilityEnabled)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accessibility Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enable Accessibility Service so SweatLock can detect when locked apps are opened.',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => vm.requestAccessibility(),
                        child: const Text('Enable Accessibility'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${vm.blockedApps.length} apps locked',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (vm.accessibilityEnabled)
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                  ],
                ),
              ),
              Expanded(
                child: vm.isLoadingApps
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: vm.installedApps.length,
                        itemBuilder: (context, index) {
                          final app = vm.installedApps[index];
                          final packageName = app.packageName ?? '';
                          final isBlocked = vm.isAppBlocked(packageName);

                          return ListTile(
                            leading: app.icon != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      app.icon!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const CircleAvatar(child: Icon(Icons.apps)),
                            title: Text(app.name ?? packageName),
                            subtitle: Text(
                              packageName,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Switch(
                              value: isBlocked,
                              activeColor: AppColors.primaryGreen,
                              onChanged: (_) {
                                vm.toggleApp(
                                  app: app,
                                  requiredReps: defaultReps,
                                  exerciseType: defaultExercise,
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
