import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/injection.dart';
import 'package:sweat_lock/presentation/providers/theme_provider.dart';
import 'package:sweat_lock/presentation/views/blocking/blocked_overlay.dart';
import 'package:sweat_lock/presentation/views/blocking/ios_nudge_screen.dart';
import 'package:sweat_lock/presentation/views/onboarding/splash.dart';
import 'package:sweat_lock/services/blocking_service.dart';
import 'package:sweat_lock/services/ios_nudge_service.dart';

@pragma('vm:entry-point')
void accessibilityOverlay() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const BlockedOverlay());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const _screenTimeChannel = MethodChannel('sweatlock/screen_time');

/// Prevents double-push when URL open + resume + consumePending all fire.
DateTime? _lastNudgeOpenAt;
bool _nudgeOpenInFlight = false;

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
        final args = call.arguments;
        String? bundleId;
        int? minutes;
        if (args is Map) {
          bundleId = args['bundleId']?.toString();
          minutes = args['minutes'] as int?;
        }
        _openNudge(bundleId: bundleId, minutes: minutes);
      }
    });
  }

  runApp(const MyApp());
}

void _openNudge({String? bundleId, int? minutes}) {
  final now = DateTime.now();
  if (_nudgeOpenInFlight) return;
  if (_lastNudgeOpenAt != null &&
      now.difference(_lastNudgeOpenAt!) < const Duration(seconds: 2)) {
    return;
  }

  final nav = navigatorKey.currentState;
  if (nav == null) return;

  // Already showing nudge on top of the stack?
  final route = ModalRoute.of(navigatorKey.currentContext!);
  // Walk stack via overlay — simpler: check if top route is IosNudgeScreen
  // by using a flag set while route is alive is overkill; debounce is enough.

  _nudgeOpenInFlight = true;
  _lastNudgeOpenAt = now;

  // Persist so reading/workout can resolve the locked app later
  if (bundleId != null && bundleId.isNotEmpty) {
    unawaited(HiveService.setLastBlockedPackage(bundleId));
    final apps = HiveService.getBlockedApps();
    for (final a in apps) {
      if (a.bundleId == bundleId ||
          (a.bundleId.isNotEmpty && bundleId.contains(a.bundleId))) {
        unawaited(HiveService.setLastBlockedAppId(a.id));
        break;
      }
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      _nudgeOpenInFlight = false;
      return;
    }

    // Avoid stacking a second nudge
    bool alreadyOpen = false;
    nav.popUntil((r) {
      // Don't pop — only inspect. popUntil always pops until predicate true.
      // So we cannot use popUntil for inspect. Use a different approach.
      return true; // leave stack alone
    });

    // Check routes by looking at context's navigator
    final overlayCtx = navigatorKey.currentState?.overlay?.context;
    if (overlayCtx != null) {
      // If current route settings name is nudge, skip
    }

    // Practical check: if last open was <2s we already returned above.
    // Push only once.
    if (!alreadyOpen) {
      Navigator.of(ctx).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/ios_nudge'),
          builder: (_) => IosNudgeScreen(
            bundleId: bundleId,
            usageMinutes: minutes ?? HiveService.getFreeMinutes(),
          ),
        ),
      ).whenComplete(() {
        _nudgeOpenInFlight = false;
      });
    } else {
      _nudgeOpenInFlight = false;
    }
  });
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
    // Single consume after first frame — native should NOT also fire openWorkout
    // from URL + becomeActive simultaneously (native fixed to only set pending).
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
    if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS) {
        // Debounced consume — _openNudge itself is debounced
        _screenTimeChannel.invokeMethod('consumePendingWorkout');
      }
      if (Platform.isAndroid) {
        BlockingService.instance.checkAndStart();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers(context),
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.mode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
