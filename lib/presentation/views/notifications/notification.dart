import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                spacing: 15,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today".toUpperCase(),
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.headlineLarge!.color!.darken(),
                    ),
                  ),

                  ...List.generate(2, (index) {
                    return _notificationTile(
                      title: "5-Day Streak!",
                      icon: Icon(Icons.leaderboard),
                      color: AppColors.primaryGreen,
                      subtitle: "Keep the momemtum going!",
                      time: "1h ago",
                      isRead: index.isEven,
                    );
                  }),

                  Text(
                    "Yesterday".toUpperCase(),
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.headlineLarge!.color!.darken(),
                    ),
                  ),

                  ...List.generate(2, (index) {
                    return _notificationTile(
                      title: "Screen time unlocked",
                      icon: Icon(Icons.lock),
                      color: AppColors.red,
                      subtitle:
                          "you've unlocked 30 minutes of screen time. Great job!",
                      time: "1d ago",
                      isRead: index.isEven,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile({
    required String title,
    required Icon icon,
    required Color color,
    required String subtitle,
    required String time,
    required bool isRead,
  }) {
    return Container(
      decoration: isRead
          ? null
          : BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 5,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(0),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title.cap,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

              Text(
                time.capitalize,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.titleSmall!.color!.darken(),
                ),
              ),
            ],
          ),
          subtitle: Text(
            subtitle.capitalize,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).textTheme.titleMedium!.color!.darken(),
            ),
          ),
          leading: CircleAvatar(backgroundColor: color, child: icon),
        ),
      ),
    );
  }
}
