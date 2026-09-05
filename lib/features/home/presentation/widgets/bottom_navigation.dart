import 'package:flutter/material.dart';
import '../../../../core/theme/adiuva_colors.dart';

/// ADIUVA Material 3 NavigationBar Shell Component
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      elevation: 3,
      backgroundColor: isDark ? AdiuvaColors.darkSurface : AdiuvaColors.lightSurface,
      indicatorColor: AdiuvaColors.primaryContainer,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, size: 26),
          selectedIcon: Icon(Icons.home_rounded, size: 26, color: AdiuvaColors.primaryTeal),
          label: 'Home',
          tooltip: 'Home Dashboard (Tab 1 of 5)',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined, size: 26),
          selectedIcon: Icon(Icons.auto_awesome, size: 26, color: AdiuvaColors.primaryTeal),
          label: 'Assistant',
          tooltip: 'AI Assistant (Tab 2 of 5)',
        ),
        NavigationDestination(
          icon: Icon(Icons.remove_red_eye_outlined, size: 26),
          selectedIcon: Icon(Icons.remove_red_eye, size: 26, color: AdiuvaColors.primaryTeal),
          label: 'Vision',
          tooltip: 'Vision & Camera Tools (Tab 3 of 5)',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined, size: 26),
          selectedIcon: Icon(Icons.explore, size: 26, color: AdiuvaColors.primaryTeal),
          label: 'Navigate',
          tooltip: 'Navigation Helper (Tab 4 of 5)',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline, size: 26),
          selectedIcon: Icon(Icons.person, size: 26, color: AdiuvaColors.primaryTeal),
          label: 'Profile',
          tooltip: 'Profile & Settings (Tab 5 of 5)',
        ),
      ],
    );
  }
}
