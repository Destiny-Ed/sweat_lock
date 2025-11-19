import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/helpers.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/presentation/providers/onboarding_provider.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<OnboardingProvider>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 50),

            Expanded(
              child: PageView(
                children: vm.onboardingItems.asMap().entries.map((entry) {
                  return Column(
                    spacing: 20,
                    children: [
                      Container(
                        width: context.sc,
                        height: 300,
                        decoration: BoxDecoration(color: AppColors.green),
                        child: Image.asset(entry.value.image),
                      ),
                      Text(
                        entry.value.title,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(fontSize: 30),
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

            const SizedBox(height: 20),

            CustomButton(text: "Get Started"),
          ],
        ),
      ),
    );
  }
}
