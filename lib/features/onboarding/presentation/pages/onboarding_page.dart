import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/theme/adiuva_radius.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../config/routes/app_routes.dart';
import 'onboarding_1_page.dart';
import 'onboarding_2_page.dart';
import 'onboarding_3_page.dart';
import 'onboarding_4_page.dart';

/// ADIUVA Accessible Onboarding Container Page
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  final List<Widget> _pages = const [
    Onboarding1Page(),
    Onboarding2Page(),
    Onboarding3Page(),
    Onboarding4Page(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final localStorageService = sl<LocalStorageService>();
    await localStorageService.saveBool('onboarding_completed', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _totalPages - 1;

    return AccessibilityScaffold(
      pageTitle: 'Onboarding Step ${_currentPage + 1} of $_totalPages',
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Skip',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                AccessibilityScaffold.announce('Onboarding step ${index + 1} of $_totalPages');
              },
              children: _pages,
            ),
          ),
          
          // Page Indicator Dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AdiuvaSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.25),
                    borderRadius: AdiuvaRadius.borderRadiusPill,
                  ),
                );
              }),
            ),
          ),

          AdiuvaSpacing.gapLg,

          // Next / Get Started Action Button (56dp min target)
          CustomButton.primary(
            label: isLastPage ? 'Get Started' : 'Continue',
            leadingIcon: isLastPage ? Icons.check_circle_outline : Icons.arrow_forward,
            onPressed: _nextPage,
          ),
          
          AdiuvaSpacing.gapMd,
        ],
      ),
    );
  }
}
