import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:flutter_accessibility_service/constants.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/presentation/providers/main_activity_provider.dart';
import 'package:sweat_lock/presentation/views/dashboard/dashboard.dart';
import 'package:sweat_lock/presentation/views/settings/settings.dart';
import 'package:sweat_lock/presentation/views/stats/stats.dart';

class MainActivity extends StatefulWidget {
  const MainActivity({super.key});

  @override
  State<MainActivity> createState() => _MainActivityState();
}

class _MainActivityState extends State<MainActivity> {
  final List<Widget> _screens = const [
    DashboardScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _setupAccessibility();
    }else {
      log("Setup Ios Blocking feature");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MainActivityProvider>(
      builder: (context, mainVm, child) {
        return Scaffold(
          body: _screens[mainVm.currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            elevation: 10,
            enableFeedback: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            currentIndex: mainVm.currentIndex,
            onTap: (i) => mainVm.currentIndex = i,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).textTheme.titleSmall?.color,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setupAccessibility() async {
    final List<String> blockedPackages = [
      'com.tiktok',
      'com.instagram.android',
      'com.google.android.youtube',
    ]; // Example blocked apps
    bool isEnabled =
        await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    if (!isEnabled) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
    }

    // Listen for events
    FlutterAccessibilityService.accessStream.listen((AccessibilityEvent event) {
      if (event.eventType == EventType.typeWindowStateChanged &&
          blockedPackages.contains(event.packageName)) {
        // Blocked app launched - show overlay
        FlutterAccessibilityService.showOverlayWindow();
      }
    });
  }
}
