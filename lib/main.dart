import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/injection.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/blocking/blocked_overlay.dart';
import 'package:sweat_lock/presentation/views/blocking/ios_nudge_screen.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

/// Accessibility overlay entry point (Android only)
@pragma('vm:entry-point')
void accessibilityOverlay() {
  runApp(const BlockedOverlay());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Android hard blocking
  if (Platform.isAndroid) {
    await BlockingService.instance.checkAndStart();
  }

  // iOS soft nudge monitoring
  if (Platform.isIOS) {
    IosNudgeService.instance.loadSavedSelections();
    IosNudgeService.instance.setNudgeCallback((bundleId, minutes) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => IosNudgeScreen(
            bundleId: bundleId,
            usageMinutes: minutes,
          ),
        ),
      );
    });
    IosNudgeService.instance.startMonitoring();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnboarded = HiveService.isOnboardingComplete();

    return MultiProvider(
      providers: providers(context),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: isOnboarded ? const MainActivity() : const LoginView(),
      ),
    );
  }
}


