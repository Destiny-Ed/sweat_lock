import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
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
        title: const Text('Your Stats'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<StatsProvider>(
        builder: (context, stats, child) {
          final top = stats.topAppByReps;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lifetime Total'.cap,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${stats.lifetimeReps} reps'.cap,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            4.height(),
                            Text(
                              '${stats.totalReps} in ${stats.selectedTab}'.cap,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '= ${(stats.lifetimeReps * 250).toString()} meters scrolled prevented 😂'
                              .cap,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Theme.of(context).cardColor,
                        ),
                        child: Row(
                          children: List.generate(stats.statTab.length, (index) {
                            final tab = stats.statTab[index];
                            final isSelected = tab == stats.selectedTab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => stats.selectedTab = tab,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.all(10),
                                  decoration: isSelected
                                      ? BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          color: Theme.of(context)
                                              .secondaryHeaderColor,
                                        )
                                      : null,
                                  child: Text(
                                    tab.cap,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      10.height(),
                      StatsBarChart(weeklyValues: stats.weeklyReps),
                      16.height(),
                      Text(
                        'Screen time cost'.cap,
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
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'most expensive app'.cap,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Text(
                            top?.key ?? 'None yet',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).secondaryHeaderColor,
                            child: const Icon(Icons.apps),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${top?.value ?? 0} reps'.cap,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                stats.selectedTab.cap,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
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
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'workouts completed'.cap,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Text(
                            stats.selectedTab.cap,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primaryGreen.withValues(alpha: 0.2),
                            child: const Icon(Icons.fitness_center,
                                color: AppColors.primaryGreen),
                          ),
                          trailing: Text(
                            '${stats.totalWorkouts}',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                      ),
                      30.height(),
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
