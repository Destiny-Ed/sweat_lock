import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/presentation/providers/stats_provider.dart';
import 'package:sweat_lock/presentation/views/stats/bar_chart_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Stats"),
        automaticallyImplyLeading: false,
      ),

      body: Consumer<StatsProvider>(
        builder: (context, statsProvider, child) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: context.screenSize().width,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).cardColor,
                        ),
                        child: Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lifetime Total".cap,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              "4,827 push-ups".cap,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          "= 1,205,000 meters scrolled prevented 😂".cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),

                      ///Display tab
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).cardColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            statsProvider.statTab.length,
                            (index) {
                              final tab = statsProvider.statTab[index];
                              final isSelected =
                                  tab == statsProvider.selectedTab;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    statsProvider.selectedTab = tab;
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    padding: const EdgeInsets.all(10),
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            color: Theme.of(
                                              context,
                                            ).secondaryHeaderColor,
                                          )
                                        : null,
                                    child: Text(
                                      tab.cap,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      10.height(),
                      StatsBarChart(),

                      //
                      Text(
                        "Screen time cost".cap,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      10.height(),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(0),
                          title: Text(
                            "most expensive app".cap,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Text(
                            "instagram",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).secondaryHeaderColor,
                            child: Icon(Icons.camera),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "1,240 reps".cap,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                "this month".cap,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).cardColor,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(0),
                          title: Text(
                            "most used app".cap,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Text(
                            "instagram",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).secondaryHeaderColor,
                            child: Icon(Icons.camera),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "1,240 reps".cap,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                "this month".cap,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
