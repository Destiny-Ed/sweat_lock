import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/enums.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/presentation/providers/onboarding_provider.dart';
import 'package:sweat_lock/presentation/views/onboarding/choose_apps_onboarding.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingProvider>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            (context.screenSize().width / 3).height(),
            Expanded(
              child: PageView(
                onPageChanged: (index) => vm.currentIndex = index,
                children: vm.onboardingItems.asMap().entries.map((entry) {
                  return Column(
                    spacing: 25,
                    children: [
                      Container(
                        width: context.screenSize().width,
                        height: 300,
                        decoration: BoxDecoration(color: AppColors.green),
                        child: Image.asset(entry.value.image),
                      ),
                      Text(
                        entry.value.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(fontSize: 30),
                      ),
                      Text(
                        entry.value.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),

            ///indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: vm.onboardingItems.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: vm.currentIndex == entry.key ? 40 : 20,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: vm.currentIndex == entry.key
                        ? Theme.of(context).primaryColor
                        : AppColors.gray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),

            40.height(),

            CustomButton(
              text: "Get Started",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChooseAppsOnboarding(),
                  ),
                );
              },
            ),
            40.height(),
          ],
        ),
      ),
    );
  }
}
