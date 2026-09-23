import 'package:flutter/material.dart';
import 'package:sweat_lock/core/constant.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/data/local/hive_service.dart';
import 'package:sweat_lock/presentation/views/auth/login.dart';
import 'package:sweat_lock/presentation/views/main_activity.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final onboarded = HiveService.isOnboardingComplete();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            onboarded ? const MainActivity() : const LoginView(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGreen,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.primaryGreen,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 52,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  appName,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Earn your screen time',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
