import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/enums.dart';
import 'package:sweat_lock/core/extensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings"), automaticallyImplyLeading: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Exercise Settings",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Reps per session",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              "25",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),

                        Slider(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          value: 20,
                          min: 5,
                          max: 100,
                          divisions: 5,
                          onChanged: (v) {},
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "App Exercises",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Column(
                      children: List.generate(2, (index) {
                        return ListTile(
                          contentPadding: const EdgeInsets.all(0),
                          title: Text(
                            "Instagram",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Text(
                            "push-ups",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).secondaryHeaderColor,
                            child: Icon(Icons.camera),
                          ),
                          trailing: IconButton(
                            color: Theme.of(
                              context,
                            ).textTheme.titleSmall!.color,
                            onPressed: () {},
                            icon: Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        );
                      }),
                    ),
                  ),

                  Text(
                    "Security & Access",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Emergency Unlock",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Theme.of(context).secondaryHeaderColor,
                          ),
                          child: Text(
                            "1 left today".cap,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "Personalization",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Workout Music: Electronic",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ],
                    ),
                  ),
                  Text("About", style: Theme.of(context).textTheme.titleMedium),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "About $appName",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Icon(
                          Icons.info,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Contact Support",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Icon(
                          Icons.support_agent,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "Account",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).cardColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Logout",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Icon(
                          Icons.exit_to_app,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ],
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
