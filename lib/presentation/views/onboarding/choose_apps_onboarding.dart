import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/models/workout_model.dart';
import 'package:sweat_lock/presentation/modals/single_list_modal.dart';
import 'package:sweat_lock/presentation/providers/apps_onboarding_provider.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/presentation/widgets/busy_overlay.dart';
import 'package:sweat_lock/presentation/widgets/error_reload_state.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';
import 'package:sweat_lock/service/access_request_manager.dart';
 
class ChooseAppsOnboarding extends StatefulWidget {
  const ChooseAppsOnboarding({super.key});

  @override
  State<ChooseAppsOnboarding> createState() => _ChooseAppsOnboardingState();
}

class _ChooseAppsOnboardingState extends State<ChooseAppsOnboarding> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppsOnboardingProvider>().currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppsOnboardingProvider>();
    return Scaffold(
      appBar: AppBar(title: Text("Step ${vm.currentIndex} of ${vm.maxIndex}")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) {
                  vm.currentIndex = value + 1;
                },
                children: [
                  AppOnboardingStepOne(vm: vm),
                  AppOnboardingStepTwo(vm: vm),
                  AppOnboardingStepThree(vm: vm),
                ],
              ),
            ),

            10.height(),

            CustomButton(
              text: buttonText(vm.currentIndex).cap,
              onTap: () async {
                if (vm.currentIndex == 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeIn,
                  );
                } else if (vm.currentIndex == 2) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeIn,
                  );
                } else {
                  //index 3
                  ///save all
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MainActivity()),
                  );
                }
              },
            ),
            40.height(),
          ],
        ),
      ),
    );
  }

  String buttonText(int index) {
    String text = "continue";
    switch (index) {
      case 1:
        text = "lock apps & continue";
      case 2:
        text = "continue";
      case 3:
        text = "save & continue";
    }
    return text;
  }
}

class AppOnboardingStepOne extends StatefulWidget {
  final AppsOnboardingProvider vm;
  const AppOnboardingStepOne({super.key, required this.vm});

  @override
  State<AppOnboardingStepOne> createState() => _AppOnboardingStepOneState();
}

class _AppOnboardingStepOneState extends State<AppOnboardingStepOne> {
  @override
  void initState() {
    super.initState();
    widget.vm.loadAndroidApps();
  }

  @override
  Widget build(BuildContext context) {
    return BusyOverlay(
      show: widget.vm.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 15,
        children: [
          Text(
            "choose the apps that ruin your life".cap,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 30),
          ),
          Text(
            "select the apps you want to lock. You'll earn time back by exercising."
                .capitalize,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          5.height(),

          if (Platform.isIOS)
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: context.screenSize().width / 2,
                child: CustomButton(
                  text: "pick iOS apps to block",
                  onTap: () {
                    AccessRequestManager.pickIOSApps();
                  },
                ),
              ),
            ),

          5.height(),

          if (Platform.isAndroid &&
              widget.vm.availableAndroidApps.isEmpty &&
              !widget.vm.isLoading)
            ErrorReloadStateWidget(
              onRetry: widget.vm.loadAndroidApps,
              message: "No App(s) Loaded",
            ),

          if (Platform.isAndroid &&
              widget.vm.availableAndroidApps.isNotEmpty &&
              !widget.vm.isLoading)
            Expanded(
              child: GridView(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 60,
                ),
                children: List.generate(widget.vm.availableAndroidApps.length, (
                  index,
                ) {
                  final apps = widget.vm.availableAndroidApps[index];

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: 10,
                      left: index.isOdd ? 10 : 0,
                      right: index.isEven ? 10 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        CircleAvatar(),
                        Text(
                          apps.appName.cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Checkbox(
                          shape: OvalBorder(),
                          value: widget.vm.isAppSelected(apps.packageName),
                          onChanged: (value) {
                            widget.vm.updateSelectedBlockedApps(
                              AppModel(
                                appName: apps.appName,
                                icon: apps.apkFilePath,
                                packageName: apps.packageName,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

          if (Platform.isIOS &&
              widget.vm.selectedBlockedApps.isNotEmpty &&
              !widget.vm.isLoading)
            Expanded(
              child: GridView(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 60,
                ),
                children: List.generate(widget.vm.selectedBlockedApps.length, (
                  index,
                ) {
                  final apps = widget.vm.selectedBlockedApps[index];

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: 10,
                      left: index.isOdd ? 10 : 0,
                      right: index.isEven ? 10 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        CircleAvatar(),
                        Text(
                          apps.appName.cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Checkbox(
                          shape: OvalBorder(),
                          value: widget.vm.isAppSelected(apps.packageName),
                          onChanged: (value) {
                            widget.vm.updateSelectedBlockedApps(apps);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
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
      spacing: 15,
      children: [
        Text(
          "tune your workout".cap,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 30),
        ),
        Text(
          "pick your favorite music genres. We'll build playlists to keep you motivated."
              .capitalize,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        10.height(),

        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: List.generate(vm.musicGenres.length, (index) {
              final genre = vm.musicGenres[index];
              final isSelected = vm.selectedGenres.contains(
                genre.toLowerCase(),
              );
              return GestureDetector(
                onTap: () => vm.selectedGenres = genre,
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
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          genre.cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Checkbox(
                        shape: OvalBorder(),
                        value: isSelected,
                        onChanged: (value) {
                          vm.selectedGenres = genre;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class AppOnboardingStepThree extends StatelessWidget {
  final AppsOnboardingProvider vm;
  AppOnboardingStepThree({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 15,
      children: [
        Text(
          "set your challenges".cap,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 30),
        ),
        Text(
          "choose a workout to unlock each app."
              .capitalize
              .capitalize
              .capitalize,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        10.height(),

        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: List.generate(4, (index) {
              final selectedWorkout = vm.workouts.firstWhere(
                (element) =>
                    element.workout.toLowerCase() ==
                    vm.selectedWorkout?.workout.toLowerCase(),
                orElse: () => WorkoutModel(
                  workout: "workout",
                  isReps: true,
                  duration: 20,
                ),
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: AppColors.darkGray.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        CircleAvatar(),
                        Expanded(
                          child: Text(
                            "instagram".cap,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            showGenrePickerBottomSheet(
                              context: context,
                              title: "select workout",
                              items: vm.workouts.map((e) => e.workout).toList(),

                              onGenreSelected: (workout) {
                                //Update this later
                                vm.selectedWorkout = vm.workouts
                                    .where(
                                      (e) =>
                                          e.workout.toLowerCase() ==
                                          workout.toLowerCase(),
                                    )
                                    .first;
                              },
                              currentSelected: selectedWorkout.workout,
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                selectedWorkout.workout.cap,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: AppColors.primaryGreen),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 40,
                                color: AppColors.primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Divider(
                        color: AppColors.darkGray.withOpacity(0.5),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Icon(
                          getIconAndString(selectedWorkout.isReps).icon,
                          size: 25,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                        Expanded(
                          child: Text(
                            getIconAndString(selectedWorkout.isReps).title.cap,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Row(
                          spacing: 10,
                          children: [
                            GestureDetector(
                              onTap: () {
                                ///decrement
                              },
                              child: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                foregroundColor: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                                child: Icon(Icons.remove),
                              ),
                            ),

                            Text(
                              selectedWorkout.duration.toString(),
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            GestureDetector(
                              onTap: () {
                                //increment
                              },
                              child: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                foregroundColor: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.color,
                                child: Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  ({IconData icon, String title}) getIconAndString(bool isReps) {
    if (isReps) {
      return (icon: Icons.replay, title: "reps");
    } else {
      return (icon: Icons.alarm, title: "duration(sec)");
    }
  }
}
