import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/injection.dart';
import 'package:sweat_lock/presentation/views/blocking/blocked_overlay.dart';
import 'package:sweat_lock/presentation/views/blocking/ios_nudge_screen.dart';
import 'package:sweat_lock/presentation/views/onboarding/splash.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

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
      _openNudge(bundleId: bundleId, minutes: minutes);
    });
    IosNudgeService.instance.startMonitoring();

    _screenTimeChannel.setMethodCallHandler((call) async {
      if (call.method == 'openWorkout') {
        _openNudge();
      }
    });
  }

  runApp(const MyApp());
}

void _openNudge({String? bundleId, int? minutes}) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;

  Navigator.of(ctx).push(
    MaterialPageRoute(
      builder: (_) => IosNudgeScreen(
        bundleId: bundleId,
        usageMinutes: minutes ?? HiveService.getFreeMinutes(),
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
    return MultiProvider(
      providers: providers(context),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
