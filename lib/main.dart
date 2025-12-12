import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/injection.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/dashboard/blocked_screen.dart';
import 'package:sweat_lock/service/access_request_manager.dart';

@pragma("vm:entry-point")
void accessibilityOverlay() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: BlockedScreen()),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Hive.initFlutter();

  // NotificationService().init();

  runApp(const MyApp());

  // Check immediately when app opens
  final request = await AccessRequestManager.checkForPendingRequest();
  if (request != null) {
    print("User requested access to: ${request['appName']}");
    log("User requested access to: ${request['timestamp']}");
    // Show your "Allow 10 more minutes?" dialog immediately!
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers(context),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const LoginView(),
      ),
    );
  }
}
