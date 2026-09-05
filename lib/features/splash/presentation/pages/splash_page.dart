import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/adiuva_colors.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../config/routes/app_routes.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

/// ADIUVA Accessible Splash Screen with Persistent Login Routing
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAppStateAndNavigate();
  }

  Future<void> _checkAppStateAndNavigate() async {
    // Artificial minimum delay for smooth visual transition
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final localStorageService = sl<LocalStorageService>();
    final onboardingCompleted = (await localStorageService.getBool('onboarding_completed')) ?? false;

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Persistent login gate: Check and resolve Firebase Auth status
    final isAuthenticated = await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (!onboardingCompleted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    } else if (isAuthenticated) {
      // Authenticated user goes directly to Home Dashboard
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      // Unauthenticated user goes to Login Page
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AccessibilityScaffold(
      pageTitle: 'Splash Screen',
      initialAnnouncement: 'Welcome to ADIUVA. Loading application state.',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Branding Icon / Logo
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AdiuvaColors.primaryTeal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.accessibility_new,
                size: 72,
                color: Colors.white,
              ),
            ),
            AdiuvaSpacing.gapLg,
            Text(
              'ADIUVA',
              style: theme.textTheme.displayMedium?.copyWith(
                color: AdiuvaColors.primaryTeal,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            AdiuvaSpacing.gapSm,
            Text(
              'Every Need, One Solution',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            AdiuvaSpacing.gapXl,
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(AdiuvaColors.primaryTeal),
                backgroundColor: AdiuvaColors.slate200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
