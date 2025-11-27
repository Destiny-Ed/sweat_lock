import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';

class StatsBarChart extends StatefulWidget {
  const StatsBarChart({super.key});

  List<Color> get availableColors => const <Color>[
    Colors.purple,
    Colors.yellow,
    Colors.blue,
    Colors.orange,
    Colors.pink,
    Colors.red,
  ];

  @override
  State<StatefulWidget> createState() => StatsBarChartState();
}

class StatsBarChartState extends State<StatsBarChart> {
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  bool isPlaying = false;

  final Color barBackgroundColor = Colors.white.darken().withValues(alpha: 0.3);
  final Color barColor = Colors.green;
  final Color touchedBarColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "This week".cap,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    10.height(),
                    Text(
                      "254 reps",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    10.height(),

                    Row(
                      children: [
                        Text(
                          "vs. last week ",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          "+15%",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Theme.of(context).primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
                30.height(),
                Expanded(
                  child: BarChart(
                    isPlaying ? randomData() : mainBarData(),
                    duration: animDuration,
                  ),
                ),
                12.height(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.green,
                ),
                onPressed: () {
                  setState(() {
                    isPlaying = !isPlaying;
                    if (isPlaying) {
                      refreshState();
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color? barColor = Colors.green,
    double width = 22,
    List<int> showTooltips = const [],
  }) {
    barColor ??= barColor;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched ? touchedBarColor : barColor,
          width: width,
          borderSide: isTouched
              ? BorderSide(color: touchedBarColor.darken(80))
              : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(
    7,
    (i) => switch (i) {
      0 => makeGroupData(0, 5, isTouched: i == touchedIndex),
      1 => makeGroupData(1, 6.5, isTouched: i == touchedIndex),
      2 => makeGroupData(2, 5, isTouched: i == touchedIndex),
      3 => makeGroupData(3, 7.5, isTouched: i == touchedIndex),
      4 => makeGroupData(4, 9, isTouched: i == touchedIndex),
      5 => makeGroupData(5, 11.5, isTouched: i == touchedIndex),
      6 => makeGroupData(6, 6.5, isTouched: i == touchedIndex),
      _ => throw Error(),
    },
  );

  BarChartData mainBarData() {
    return BarChartData(
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Theme.of(context).cardColor,
          tooltipHorizontalAlignment: FLHorizontalAlignment.right,
          tooltipMargin: -10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String weekDay = switch (group.x) {
              0 => 'Monday',
              1 => 'Tuesday',
              2 => 'Wednesday',
              3 => 'Thursday',
              4 => 'Friday',
              5 => 'Saturday',
              6 => 'Sunday',
              _ => throw Error(),
            };
            return BarTooltipItem(
              '$weekDay\n',
              Theme.of(context).textTheme.titleMedium!,
              children: <TextSpan>[
                TextSpan(
                  text: ((rod.toY - 1).toStringAsFixed(1)).toString(),
                  style: Theme.of(context).textTheme.titleMedium!,
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: showingGroups(),
      gridData: const FlGridData(show: false),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    TextStyle style = Theme.of(context).textTheme.titleMedium!;
    String text = switch (value.toInt()) {
      0 => 'Mon',
      1 => 'Tue',
      2 => 'Wed',
      3 => 'Thu',
      4 => 'Fri',
      5 => 'Sat',
      6 => 'Sun',
      _ => '',
    };
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: Text(text, style: style),
    );
  }

  BarChartData randomData() {
    return BarChartData(
      barTouchData: const BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(
        7,
        (i) => makeGroupData(
          i,
          Random().nextInt(15).toDouble() + 6,
          barColor: widget
              .availableColors[Random().nextInt(widget.availableColors.length)],
        ),
      ),
      gridData: const FlGridData(show: false),
    );
  }

  Future<dynamic> refreshState() async {
    setState(() {});
    await Future<dynamic>.delayed(
      animDuration + const Duration(milliseconds: 50),
    );
    if (isPlaying) {
      await refreshState();
    }
  }
}
