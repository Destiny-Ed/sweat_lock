import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/injection.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/blocking/blocked_overlay.dart';
import 'package:sweat_lock/presentation/views/blocking/ios_nudge_screen.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/presentation/views/workout/workout_screen.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

/// Accessibility overlay entry point (Android only)
@pragma('vm:entry-point')
void accessibilityOverlay() {
  runApp(const BlockedOverlay());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const _screenTimeChannel = MethodChannel('sweatlock/screen_time');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  if (Platform.isAndroid) {
    await BlockingService.instance.checkAndStart();
  }

  if (Platform.isIOS) {
    IosNudgeService.instance.loadSavedSelections();
    IosNudgeService.instance.setNudgeCallback((bundleId, minutes) {
      _openNudgeOrWorkout(bundleId: bundleId, minutes: minutes);
    });
    IosNudgeService.instance.startMonitoring();

    // Native → Flutter: shield "Start Workout" or deep link
    _screenTimeChannel.setMethodCallHandler((call) async {
      if (call.method == 'openWorkout') {
        _openNudgeOrWorkout();
      }
    });
  }

  runApp(const MyApp());
}

void _openNudgeOrWorkout({String? bundleId, int? minutes}) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;

  final apps = HiveService.getBlockedApps();
  final app = apps.isNotEmpty ? apps.first : null;

  Navigator.of(ctx).push(
    MaterialPageRoute(
      builder: (_) => WorkoutScreen(
        targetReps: app?.requiredReps,
        exerciseType: app?.exerciseType,
        unlockedAppId: app?.id,
        playlistName: app?.playlistName,
        playlistUrl: app?.playlistUrl,
        appName: app?.appName,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Handle cold start after shield button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Platform.isIOS) {
        _screenTimeChannel.invokeMethod('consumePendingWorkout');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isIOS) {
      _screenTimeChannel.invokeMethod('consumePendingWorkout');
    }
  }

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
