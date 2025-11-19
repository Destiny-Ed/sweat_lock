import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/enums.dart';
import 'package:sweat_lock/presentation/providers/apps_onboarding_provider.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class ChooseAppsOnboarding extends StatelessWidget {
  const ChooseAppsOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppsOnboardingProvider>();
    return Scaffold(
      appBar: AppBar(title: Text("Step ${vm.currentIndex} of ${vm.maxIndex}")),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          spacing: 15,
          children: [
            Text(
              "choose the apps that ruin your life".capitalize,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 30),
            ),
            Text(
              "select the apps you want to lock. You'll earn time back by exercising."
                  .capitalize,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            10.height(),

            Expanded(
              child: GridView(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 60,
                ),
                children: List.generate(10, (index) {
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
                          "Tiktok",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Checkbox(
                          shape: OvalBorder(),
                          value: true,
                          onChanged: (value) {},
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            10.height(),

            CustomButton(
              text: "lock apps & continue".cap,
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
