import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sweat_lock/core/extensions.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Stack(
            children: [
              ///header
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).secondaryHeaderColor,
                        ),
                        child: Text(
                          "End workout".cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),

                      CircularPercentIndicator(
                        radius: 50.0,
                        animation: true,
                        animationDuration: 1200,
                        lineWidth: 5.0,
                        percent: 0.4,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "8",
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(fontSize: 25),
                            ),
                            Text(
                              "/15",
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                        circularStrokeCap: CircularStrokeCap.butt,
                        backgroundColor: Theme.of(
                          context,
                        ).textTheme.titleSmall!.color!.darken(),
                        progressColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(spacing: 20, children: [
                          
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        leading: CircleAvatar(),
                        title: Text(
                          "eye of the tiger".cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          "Survivor".cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        trailing: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(Icons.play_arrow_outlined),
                        ),
                      ),
                      Slider(
                        padding: const EdgeInsets.all(10),
                        value: 50,
                        max: 100,
                        min: 0,
                        inactiveColor: Theme.of(
                          context,
                        ).textTheme.titleLarge!.color?.darken(),
                        activeColor: Theme.of(
                          context,
                        ).textTheme.titleLarge!.color,
                        onChanged: (value) {},
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "1:17",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              "2:23",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),

                      30.height(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
