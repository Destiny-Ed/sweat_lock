import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class BlockedAppsDetailsScreen extends StatefulWidget {
  const BlockedAppsDetailsScreen({super.key});

  @override
  State<BlockedAppsDetailsScreen> createState() =>
      _BlockedAppsDetailsScreenState();
}

class _BlockedAppsDetailsScreenState extends State<BlockedAppsDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Instagram")),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                spacing: 20,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.blue,
                    radius: 40,
                    child: Icon(Icons.tiktok),
                  ),

                  Text(
                    "25 push-ups".cap,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge!.copyWith(fontSize: 30),
                  ),

                  Text(
                    "unlock for 15 minutes".cap,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              spacing: 10,
                              children: [
                                Icon(
                                  Icons.sports,
                                  color: Theme.of(context).primaryColor,
                                  size: 40,
                                ),
                                Text(
                                  "25 reps".cap,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),

                                Text(
                                  "required".capitalize,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),

                            Column(
                              spacing: 10,
                              children: [
                                Icon(
                                  Icons.alarm,
                                  color: Theme.of(context).primaryColor,
                                  size: 40,
                                ),
                                Text(
                                  "15 mins".cap,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),

                                Text(
                                  "earned".capitalize,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        15.height(),
                        Slider(
                          padding: const EdgeInsets.all(0),
                          value: 50,
                          max: 100,
                          inactiveColor: Theme.of(
                            context,
                          ).textTheme.headlineSmall!.color!.lighten(),
                          min: 0,
                          onChanged: (value) {},
                        ),
                        10.height(),
                        Text(
                          "you've got this!".capitalize,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),

                  40.height(),
                  CustomButton(
                    text: "start workout",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutScreen(),
                        ),
                      );
                    },
                  ),

                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "swap exercise".cap,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
