import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/presentation/views/dashboard/blocked_apps_details.dart';
import 'package:sweat_lock/presentation/views/notifications/notification.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.person),
        title: Text("Good morning, John"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
            icon: Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).cardColor,

                    radius: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Text(
                          "37",
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        Text(
                          "Push-ups today",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  10.height(),
                  Text(
                    "5 days streaks",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  30.height(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Blocked Apps",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  15.height(),

                  ...List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlockedAppsDetailsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ListTile(
                          title: Text(
                            "Social App",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Text(
                            "Blocked until 50 reps",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).secondaryHeaderColor,
                          ),
                          trailing: IconButton(
                            color: Theme.of(context).primaryColor,
                            onPressed: () {},
                            icon: Icon(Icons.lock),
                          ),
                        ),
                      ),
                    );
                  }),

                  ///block app button
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: CustomButton(
                      onTap: () {},
                      text: "Block apps to reduce doomscrolling",
                    ),
                  ),
                  // 60.height(),
                ],
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {},
      //   icon: Icon(Icons.lock),
      //   backgroundColor: Theme.of(context).primaryColor,
      //   enableFeedback: true,
      //   label: Text("Block apps to reduce doomscrolling"),
      // ),
    );
  }
}
