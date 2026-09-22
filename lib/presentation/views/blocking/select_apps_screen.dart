import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';

class SelectAppsScreen extends StatefulWidget {
  const SelectAppsScreen({super.key});

  @override
  State<SelectAppsScreen> createState() => _SelectAppsScreenState();
}

class _SelectAppsScreenState extends State<SelectAppsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BlockingProvider>();
      vm.loadInstalledApps();
      vm.checkAccessibility();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Apps to Lock')),
      body: Consumer<BlockingProvider>(
        builder: (context, vm, _) {
          if (!Platform.isAndroid) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Full app blocking is available on Android.\n\niOS uses smart usage nudges instead.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              // Accessibility banner
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

              // Selected count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${vm.blockedApps.length} apps locked',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (vm.accessibilityEnabled)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
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
                              activeColor: Theme.of(context).primaryColor,
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
