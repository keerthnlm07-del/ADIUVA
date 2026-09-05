import 'package:flutter/material.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../config/routes/route_generator.dart';
import '../../../speech_assistance/presentation/pages/speech_assistance_page.dart';
import '../../../visual_assistance/presentation/pages/visual_assistance_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/bottom_navigation.dart';
import 'home_page.dart';

/// ADIUVA Persistent Navigation Shell Container
class NavigationShellPage extends StatefulWidget {
  final int initialIndex;

  const NavigationShellPage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<NavigationShellPage> createState() => _NavigationShellPageState();
}

class _NavigationShellPageState extends State<NavigationShellPage> {
  late int _currentIndex;

  static const List<String> _tabTitles = [
    'Home Dashboard',
    'AI Assistant',
    'Vision Tools',
    'Navigation Helper',
    'Profile & Settings',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      AccessibilityScaffold.announce('Switched to ${_tabTitles[index]} tab');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityScaffold(
      pageTitle: _tabTitles[_currentIndex],
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onNavigateTab: _onTabSelected),
          const SpeechAssistancePage(),
          const VisualAssistancePage(),
          const PlaceholderPage(title: 'Navigation Assistant'),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
