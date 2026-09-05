import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../core/widgets/accessibility_scaffold.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/home/presentation/pages/navigation_shell_page.dart';
import '../../features/speech_assistance/presentation/pages/voice_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/privacy_settings_page.dart';
import '../../features/profile/presentation/pages/permissions_page.dart';
import '../../features/accessibility/presentation/pages/accessibility_settings_page.dart';
import '../../features/accessibility/presentation/pages/voice_settings_page.dart';
import '../../features/accessibility/presentation/pages/language_settings_page.dart';
import '../../features/accessibility/presentation/pages/appearance_settings_page.dart';
import '../../features/emergency_sos/presentation/pages/emergency_sos_page.dart';
import '../../features/emergency_sos/presentation/pages/emergency_contacts_list_page.dart';
import '../../features/emergency_sos/presentation/pages/add_emergency_contact_page.dart';

/// ADIUVA Route Generator
/// 
/// Maps application routes to accessible screen components and transitions.
class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Splash',
          builder: (context) => const SplashPage(),
        );

      case AppRoutes.onboarding:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Onboarding',
          builder: (context) => const OnboardingPage(),
        );

      case AppRoutes.login:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Sign In',
          builder: (context) => const LoginPage(),
        );

      case AppRoutes.signup:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Sign Up',
          builder: (context) => const SignupPage(),
        );

      case AppRoutes.forgotPassword:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Forgot Password',
          builder: (context) => const ForgotPasswordPage(),
        );

      case AppRoutes.emailVerification:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Email Verification',
          builder: (context) => const EmailVerificationPage(),
        );

      case AppRoutes.home:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Home Dashboard',
          builder: (context) => const NavigationShellPage(),
        );

      case AppRoutes.aiAssistant:
        return _buildRoute(
          settings: settings,
          pageTitle: 'AI Assistant',
          builder: (context) => const NavigationShellPage(initialIndex: 1),
        );

      case AppRoutes.vision:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Vision',
          builder: (context) => const NavigationShellPage(initialIndex: 2),
        );

      case AppRoutes.voiceMode:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Voice Mode',
          builder: (context) => const VoicePage(),
        );

      case AppRoutes.navigate:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Navigate',
          builder: (context) => const NavigationShellPage(initialIndex: 3),
        );

      case AppRoutes.profile:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Profile',
          builder: (context) => const NavigationShellPage(initialIndex: 4),
        );

      case AppRoutes.accessibilitySettings:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Accessibility Settings',
          builder: (context) => const AccessibilitySettingsPage(),
        );

      case AppRoutes.voiceSettings:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Voice Settings',
          builder: (context) => const VoiceSettingsPage(),
        );

      case AppRoutes.languageSettings:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Language Settings',
          builder: (context) => const LanguageSettingsPage(),
        );

      case AppRoutes.appearanceSettings:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Appearance Settings',
          builder: (context) => const AppearanceSettingsPage(),
        );

      case AppRoutes.notifications:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Notifications',
          builder: (context) => const NotificationsPage(),
        );

      case AppRoutes.privacySettings:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Privacy Settings',
          builder: (context) => const PrivacySettingsPage(),
        );

      case AppRoutes.emergencySos:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Emergency SOS',
          builder: (context) => const EmergencySosPage(),
        );

      case AppRoutes.emergencyContacts:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Emergency Contacts',
          builder: (context) => const EmergencyContactsListPage(),
        );

      case AppRoutes.addEmergencyContact:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Add Emergency Contact',
          builder: (context) => const AddEmergencyContactPage(),
        );

      case AppRoutes.editProfile:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Edit Profile',
          builder: (context) => const PermissionsPage(),
        );

      case AppRoutes.changePassword:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Change Password',
          builder: (context) => const PlaceholderPage(title: 'Change Password'),
        );

      default:
        return _buildRoute(
          settings: settings,
          pageTitle: 'Page Not Found',
          builder: (context) => AccessibilityScaffold(
            pageTitle: 'Page Not Found',
            appBar: const CustomAppBar(title: 'Error 404'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Page not found: ${settings.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomButton.primary(
                    label: 'Go Home',
                    onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.splash),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  static PageRouteBuilder _buildRoute({
    required RouteSettings settings,
    required String pageTitle,
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (disableAnimations) {
          return child;
        }
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

/// Accessible Placeholder Page used during step-by-step feature development
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AccessibilityScaffold(
      pageTitle: title,
      appBar: CustomAppBar(title: title),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Route setup complete.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
