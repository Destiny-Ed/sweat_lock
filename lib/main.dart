import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/injection.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/blocking/blocked_overlay.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';
import 'package:sweat_lock/services/blocking_service.dart';

/// Accessibility overlay entry point (Android only)
@pragma('vm:entry-point')
void accessibilityOverlay() {
  runApp(const BlockedOverlay());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Start Android blocking listener if permission already granted
  await BlockingService.instance.checkAndStart();

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
