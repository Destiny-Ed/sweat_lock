import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';

class StatsBarChart extends StatefulWidget {
  final List<double>? weeklyValues;

  const StatsBarChart({super.key, this.weeklyValues});

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

  final Color barBackgroundColor =
      Colors.white.darken().withValues(alpha: 0.3);
  final Color barColor = AppColors.primaryGreen;
  final Color touchedBarColor = Colors.white;

  List<double> get _values {
    final v = widget.weeklyValues;
    if (v != null && v.length == 7) return v;
    return List<double>.filled(7, 0);
  }

  double get _weekTotal => _values.fold(0, (a, b) => a + b);

  double get _maxY {
    final m = _values.fold<double>(0, (a, b) => a > b ? a : b);
    return m < 10 ? 20 : m * 1.2;
  }

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
                      'Last 7 days'.cap,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    10.height(),
                    Text(
                      '${_weekTotal.round()} reps',
                      style: Theme.of(context).textTheme.headlineLarge,
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
                  color: AppColors.primaryGreen,
                ),
                onPressed: () {
                  setState(() {
                    isPlaying = !isPlaying;
                    if (isPlaying) refreshState();
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
    Color? barColor,
    double width = 22,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched ? touchedBarColor : (barColor ?? this.barColor),
          width: width,
          borderSide: isTouched
              ? BorderSide(color: touchedBarColor.darken(80))
              : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY,
            color: barBackgroundColor,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> showingGroups() => List.generate(
        7,
        (i) => makeGroupData(i, _values[i], isTouched: i == touchedIndex),
      );

  BarChartData mainBarData() {
    return BarChartData(
      maxY: _maxY,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Theme.of(context).cardColor,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final day = group.x >= 0 && group.x < 7 ? labels[group.x] : '';
            return BarTooltipItem(
              '$day\n${rod.toY.round()} reps',
              Theme.of(context).textTheme.titleMedium!,
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse?.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: showingGroups(),
      gridData: const FlGridData(show: false),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    final style = Theme.of(context).textTheme.titleMedium!;
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final text =
        value.toInt() >= 0 && value.toInt() < 7 ? labels[value.toInt()] : '';
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
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(
        7,
        (i) => makeGroupData(
          i,
          Random().nextInt(15).toDouble() + 6,
          barColor: widget.availableColors[
              Random().nextInt(widget.availableColors.length)],
        ),
      ),
      gridData: const FlGridData(show: false),
    );
  }

  Future<void> refreshState() async {
    setState(() {});
    await Future<void>.delayed(
      animDuration + const Duration(milliseconds: 50),
    );
    if (isPlaying) await refreshState();
  }
}
