import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sweat_lock/presentation/providers/apps_onboarding_provider.dart';
import 'package:sweat_lock/presentation/providers/main_activity_provider.dart';
import 'package:sweat_lock/presentation/providers/onboarding_provider.dart';
import 'package:sweat_lock/presentation/providers/stats_provider.dart';

List<SingleChildWidget> providers(BuildContext context) => [
  ChangeNotifierProvider(create: (context) => OnboardingProvider()),
  ChangeNotifierProvider(create: (context) => AppsOnboardingProvider()),
  ChangeNotifierProvider(create: (context) => MainActivityProvider()),
  ChangeNotifierProvider(create: (context) => StatsProvider()),
];
