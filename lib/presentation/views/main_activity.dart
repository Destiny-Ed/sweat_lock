import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweat_lock/core/theme.dart';
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<MainActivityProvider>(
      builder: (context, mainVm, child) {
        return Scaffold(
          body: _screens[mainVm.currentIndex],
          extendBody: true,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.lightGreen : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryGreen.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _navItem(
                    context,
                    index: 0,
                    current: mainVm.currentIndex,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => mainVm.currentIndex = 0,
                  ),
                  _navItem(
                    context,
                    index: 1,
                    current: mainVm.currentIndex,
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Stats',
                    onTap: () => mainVm.currentIndex = 1,
                  ),
                  _navItem(
                    context,
                    index: 2,
                    current: mainVm.currentIndex,
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => mainVm.currentIndex = 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem(
    BuildContext context, {
    required int index,
    required int current,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final selected = index == current;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: selected
                ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.22 : 0.2)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected
                    ? AppColors.primaryGreen
                    : (isDark ? Colors.white54 : Colors.black45),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryGreen
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
