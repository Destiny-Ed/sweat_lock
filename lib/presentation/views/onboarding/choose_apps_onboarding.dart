import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/models/blocked_app.dart';
import 'package:sweat_lock/presentation/modals/single_list_modal.dart';
import 'package:sweat_lock/presentation/providers/apps_onboarding_provider.dart';
import 'package:sweat_lock/presentation/providers/blocking_provider.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class ChooseAppsOnboarding extends StatefulWidget {
  const ChooseAppsOnboarding({super.key});

  @override
  State<ChooseAppsOnboarding> createState() => _ChooseAppsOnboardingState();
}

class _ChooseAppsOnboardingState extends State<ChooseAppsOnboarding> {
  final _pageController = PageController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AppsOnboardingProvider>();
      vm.currentIndex = 1;
      if (Platform.isAndroid) vm.loadInstalledApps();
    });
  }

  Future<void> _onContinue(AppsOnboardingProvider vm) async {
    final error = vm.validateStep(vm.currentIndex);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (vm.currentIndex < vm.maxIndex) {
      if (vm.currentIndex == 2) vm.applyGenresToApps();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeIn,
      );
      return;
    }

    setState(() => _saving = true);
    await vm.saveToHive();
    if (mounted) {
      context.read<BlockingProvider>().loadBlockedApps();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainActivity()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppsOnboardingProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Step ${vm.currentIndex} of ${vm.maxIndex}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (value) => vm.currentIndex = value + 1,
                children: [
                  AppOnboardingStepOne(vm: vm),
                  AppOnboardingStepTwo(vm: vm),
                  AppOnboardingStepThree(vm: vm),
                ],
              ),
            ),
            10.height(),
            CustomButton(
              text: _saving ? 'Saving…' : buttonText(vm.currentIndex).cap,
              onTap: _saving ? null : () => _onContinue(vm),
            ),
            40.height(),
          ],
        ),
      ),
    );
  }

  String buttonText(int index) {
    switch (index) {
      case 1:
        return 'lock apps & continue';
      case 2:
        return 'continue';
      case 3:
        return 'save & continue';
      default:
        return 'continue';
    }
  }
}

class AppOnboardingStepOne extends StatelessWidget {
  final AppsOnboardingProvider vm;
  const AppOnboardingStepOne({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'choose the apps that ruin your life'.cap,
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
        ),
        8.height(),
        Text(
          Platform.isIOS
              ? 'Use Screen Time to pick apps. Selection starts empty.'
              : 'Select from apps installed on your phone. Nothing is selected by default.'
                  .capitalize,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        16.height(),
        if (vm.selectedBlockedApps.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No apps selected yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryGreen,
                  ),
            ),
          ),
        if (Platform.isIOS) ...[
          ElevatedButton.icon(
            onPressed: vm.iosSelecting ? null : () => vm.pickIosApps(),
            icon: vm.iosSelecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.apps),
            label: Text(
              vm.iosSelecting ? 'Opening Screen Time…' : 'Select apps (Screen Time)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          12.height(),
          // Native Label(token) list for real iOS icons/names when available
          if (vm.selectedBlockedApps.any((a) => a.bundleId.isNotEmpty))
            SizedBox(
              height: 120,
              child: UiKitView(
                viewType: 'sweatlock/ios_selected_apps',
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: (_) {},
              ),
            ),
          Expanded(
            child: ListView(
              children: vm.selectedBlockedApps
                  .map(
                    (a) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primaryGreen.withValues(alpha: 0.2),
                        child: Text(
                          a.appName.isNotEmpty ? a.appName[0] : '?',
                          style: const TextStyle(color: AppColors.primaryGreen),
                        ),
                      ),
                      title: Text(a.appName),
                      subtitle: Text('${a.requiredReps} ${a.exerciseType}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            vm.removeSelected(vm.configKey(a)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ] else ...[
          Expanded(
            child: vm.loadingInstalled
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: vm.installedApps.length,
                    itemBuilder: (context, index) {
                      final app = vm.installedApps[index];
                      final package = app.packageName ?? '';
                      final selected = vm.isKeySelected(package);
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
                        title: Text(app.name ?? package),
                        subtitle: Text(
                          package,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Checkbox(
                          value: selected,
                          activeColor: AppColors.primaryGreen,
                          shape: const OvalBorder(),
                          onChanged: (_) => vm.toggleInstalledApp(app),
                        ),
                        onTap: () => vm.toggleInstalledApp(app),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

class AppOnboardingStepTwo extends StatelessWidget {
  final AppsOnboardingProvider vm;
  const AppOnboardingStepTwo({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'tune your workout'.cap,
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
        ),
        8.height(),
        Text(
          'Pick music genres. Each locked app gets its own playlist (dummy for now).'
              .capitalize,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        16.height(),
        Expanded(
          child: ListView.builder(
            itemCount: vm.musicGenres.length,
            itemBuilder: (context, index) {
              final genre = vm.musicGenres[index];
              final isSelected =
                  vm.selectedGenres.contains(genre.toLowerCase());
              return GestureDetector(
                onTap: () => vm.toggleGenre(genre),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 10, left: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Theme.of(context).cardColor,
                    border: isSelected
                        ? Border.all(color: AppColors.primaryGreen)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          genre.cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Checkbox(
                        shape: const OvalBorder(),
                        value: isSelected,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (_) => vm.toggleGenre(genre),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AppOnboardingStepThree extends StatelessWidget {
  final AppsOnboardingProvider vm;
  const AppOnboardingStepThree({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final apps = vm.selectedBlockedApps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'set your challenges'.cap,
          style:
              Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
        ),
        8.height(),
        Text(
          'Each app has its own workout type, reps, and playlist.'.capitalize,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        16.height(),
        Expanded(
          child: apps.isEmpty
              ? const Center(
                  child: Text(
                    'No apps selected.\nGo back and pick at least one.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return _AppChallengeCard(app: app, vm: vm);
                  },
                ),
        ),
      ],
    );
  }
}

class _AppChallengeCard extends StatelessWidget {
  final BlockedApp app;
  final AppsOnboardingProvider vm;

  const _AppChallengeCard({required this.app, required this.vm});

  @override
  Widget build(BuildContext context) {
    final key = vm.configKey(app);
    final iconBytes = app.packageName.isNotEmpty
        ? vm.iconForPackage(app.packageName)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).cardColor,
        border: Border.all(color: AppColors.darkGray.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(iconBytes, width: 40, height: 40),
                )
              else
                CircleAvatar(
                  backgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.2),
                  child: Text(
                    app.appName.isNotEmpty ? app.appName[0] : '?',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              10.width(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.appName,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(app.playlistName,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showGenrePickerBottomSheet(
                    context: context,
                    title: 'select workout',
                    items: vm.workouts.map((e) => e.workout).toList(),
                    currentSelected: app.exerciseType,
                    onGenreSelected: (workout) {
                      vm.setAppExercise(key, workout);
                    },
                  );
                },
                child: Row(
                  children: [
                    Text(
                      app.exerciseType.cap,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                    ),
                    const Icon(Icons.arrow_drop_down,
                        color: AppColors.primaryGreen, size: 32),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.replay,
                  size: 22,
                  color: Theme.of(context).textTheme.titleMedium?.color),
              8.width(),
              Expanded(
                child: Text('reps'.cap,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              GestureDetector(
                onTap: () => vm.decrementReps(key),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: const Icon(Icons.remove, size: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${app.requiredReps}',
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
              GestureDetector(
                onTap: () => vm.incrementReps(key),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: const Icon(Icons.add, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
