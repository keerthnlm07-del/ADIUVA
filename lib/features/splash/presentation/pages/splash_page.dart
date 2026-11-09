import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAppStateAndNavigate();
  }

  void _safeNavigate(String routeName) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    debugPrint('[AUTH_FINAL] route=$routeName');
    final navState = AppRoutes.navigatorKey.currentState;
    if (navState != null) {
      navState.pushReplacementNamed(routeName);
    } else if (mounted) {
      Navigator.of(context).pushReplacementNamed(routeName);
    }
  }

  Future<void> _checkAppStateAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('[AUTH_TRACE] waiting_for_auth_state');

    // Artificial minimum delay for smooth visual transition
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted || _hasNavigated) return;

    // Persistent login gate: Await Firebase Auth session resolution
    final isAuthenticated = await authProvider.checkAuthStatus();

    if (!mounted || _hasNavigated) return;

    if (isAuthenticated) {
      final user = authProvider.user;
      final uid = user?.userId ?? '';
      debugPrint('[AUTH_TRACE] current_user=$uid');
      debugPrint('[AUTH_TRACE] session_restored');
      debugPrint('[AUTH_TRACE] loading_profile');
      debugPrint('[AUTH_TRACE] greeting_name=${user?.greetingName ?? ""}');
      debugPrint('[AUTH_TRACE] navigating_home');
      _safeNavigate(AppRoutes.home);
    } else {
      debugPrint('[AUTH_TRACE] current_user=null');
      debugPrint('[AUTH_TRACE] login_required');
      _safeNavigate(AppRoutes.login);
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
