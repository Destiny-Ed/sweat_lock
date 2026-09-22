import 'package:flutter/material.dart';
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
      context.read<AppsOnboardingProvider>().currentIndex = 1;
    });
  }

  Future<void> _onContinue(AppsOnboardingProvider vm) async {
    final error = vm.validateStep(vm.currentIndex);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (vm.currentIndex < vm.maxIndex) {
      if (vm.currentIndex == 2) {
        vm.applyGenresToApps();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeIn,
      );
      return;
    }

    // Final step — save to Hive
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
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
        ),
        8.height(),
        Text(
          'Select the apps you want to lock. Empty until you pick some.'
              .capitalize,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        16.height(),
        if (vm.selectedPackages.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No apps selected yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryGreen,
                  ),
            ),
          ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 64,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: vm.suggestedApps.length,
            itemBuilder: (context, index) {
              final app = vm.suggestedApps[index];
              final selected = vm.isSuggestedSelected(app);
              return GestureDetector(
                onTap: () => vm.toggleSuggestedApp(app),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Theme.of(context).cardColor,
                    border: selected
                        ? Border.all(color: AppColors.primaryGreen, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: selected
                            ? AppColors.primaryGreen
                            : Theme.of(context).secondaryHeaderColor,
                        child: Text(
                          app.name.characters.first,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      8.width(),
                      Expanded(
                        child: Text(
                          app.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Checkbox(
                        shape: const OvalBorder(),
                        value: selected,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (_) => vm.toggleSuggestedApp(app),
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
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
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
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
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
              CircleAvatar(
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                child: Text(
                  app.appName.characters.first,
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
                    Text(
                      app.appName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      app.playlistName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
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
                      vm.setAppExercise(app.packageName, workout);
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
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primaryGreen,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                Icons.replay,
                size: 22,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
              8.width(),
              Expanded(
                child: Text(
                  'reps'.cap,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              GestureDetector(
                onTap: () => vm.decrementReps(app.packageName),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: const Icon(Icons.remove, size: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${app.requiredReps}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              GestureDetector(
                onTap: () => vm.incrementReps(app.packageName),
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
