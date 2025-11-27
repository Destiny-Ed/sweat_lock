import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class WorkoutSuccessScreen extends StatefulWidget {
  const WorkoutSuccessScreen({super.key});

  @override
  State<WorkoutSuccessScreen> createState() => _WorkoutSuccessScreenState();
}

class _WorkoutSuccessScreenState extends State<WorkoutSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                spacing: 30,
                children: [
                  Text(
                    "25 perfect push-ups".cap,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge!.copyWith(fontSize: 24),
                  ),

                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),

                  Text(
                    "Tiktok unlocked for 45 mins".cap,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    child: ListTile(
                      title: Text(
                        "Achievement unlocked".cap,
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(color: Theme.of(context).primaryColor),
                      ),
                      subtitle: Text(
                        "meme lord level 12".cap,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall!.copyWith(),
                      ),
                      trailing: CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).cardColor,
                        child: Icon(Icons.leaderboard),
                      ),
                    ),
                  ),

                  Container(
                    width: context.screenSize().width,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).textTheme.titleSmall!.color!.darken(),
                      ),
                      borderRadius: BorderRadius.circular(15),
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    child: Column(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.share,
                          color: Theme.of(
                            context,
                          ).textTheme.titleSmall!.color?.darken(),
                        ),
                        Text(
                          '"i just did 25 push-ups to waste my life"'.cap,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(color: Theme.of(context).primaryColor),
                        ),
                        Text(
                          "your shareable story template".cap,
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall!.copyWith(),
                        ),
                      ],
                    ),
                  ),
                  30.height(),
                  CustomButton(
                    text: "Open Tiktok".cap,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainActivity()),
                      );
                    },
                  ),

                  CustomButton(
                    text: "share to stories".cap,
                    bgColor: Theme.of(context).secondaryHeaderColor,
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
