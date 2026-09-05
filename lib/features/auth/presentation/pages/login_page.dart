import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/error_dialog.dart';
import '../../../../config/routes/app_routes.dart';
import '../provider/auth_provider.dart';

/// ADIUVA Sign In Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AccessibilityScaffold.announce('Please fix the errors in the login form.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      AccessibilityScaffold.announce('Login successful. Navigating to home screen.');
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (authProvider.errorMessage != null) {
      AccessibilityScaffold.announce('Login failed: ${authProvider.errorMessage}');
      ErrorDialog.show(
        context,
        title: 'Sign In Failed',
        message: authProvider.errorMessage!,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      AccessibilityScaffold.announce('Google sign in successful. Welcome to Adiuva.');
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (authProvider.errorMessage != null &&
        !authProvider.errorMessage!.contains('cancelled')) {
      AccessibilityScaffold.announce('Google sign in failed: ${authProvider.errorMessage}');
      ErrorDialog.show(
        context,
        title: 'Google Sign In Failed',
        message: authProvider.errorMessage!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return AccessibilityScaffold(
      pageTitle: 'Sign In Screen',
      appBar: const CustomAppBar(
        title: 'Sign In',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdiuvaSpacing.gapLg,
              Text(
                'Welcome Back',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'Sign in to access your personalized ADIUVA features.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapXxl,
              
              // Email Input
              CustomTextField(
                label: 'Email Address',
                hintText: 'name@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address.';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
              AdiuvaSpacing.gapLg,

              // Password Input
              CustomTextField(
                label: 'Password',
                hintText: 'Enter your password',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  return null;
                },
              ),
              AdiuvaSpacing.gapSm,

              // Forgot Password Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                  },
                  child: Text(
                    'Forgot Password?',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              AdiuvaSpacing.gapLg,

              // Sign In Primary Action Button
              CustomButton.primary(
                label: 'Sign In',
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleLogin,
              ),
              AdiuvaSpacing.gapMd,

              // Continue with Google Button
              CustomButton.secondary(
                label: 'Continue with Google',
                leadingIcon: Icons.g_mobiledata_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleGoogleSignIn,
              ),
              AdiuvaSpacing.gapXl,

              // Link to Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: theme.textTheme.bodyLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
                    },
                    child: Text(
                      'Sign Up',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
