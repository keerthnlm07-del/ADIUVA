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

/// ADIUVA Sign Up Page
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AccessibilityScaffold.announce('Please fix the errors in the registration form.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      AccessibilityScaffold.announce('Account created successfully. Navigating to email verification.');
      Navigator.of(context).pushReplacementNamed(AppRoutes.emailVerification);
    } else if (authProvider.errorMessage != null) {
      AccessibilityScaffold.announce('Sign up failed: ${authProvider.errorMessage}');
      ErrorDialog.show(
        context,
        title: 'Sign Up Failed',
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
      pageTitle: 'Sign Up Screen',
      appBar: const CustomAppBar(
        title: 'Create Account',
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
                'Join ADIUVA',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'Create your account to enable personalized accessibility tools.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapXxl,

              // Name Input
              CustomTextField(
                label: 'Full Name',
                hintText: 'John Doe',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name.';
                  }
                  return null;
                },
              ),
              AdiuvaSpacing.gapLg,

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
                hintText: 'Minimum 8 characters',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password.';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters.';
                  }
                  return null;
                },
              ),
              AdiuvaSpacing.gapLg,

              // Confirm Password Input
              CustomTextField(
                label: 'Confirm Password',
                hintText: 'Re-enter your password',
                controller: _confirmPasswordController,
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSignup(),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              AdiuvaSpacing.gapXxl,

              // Sign Up Action Button
              CustomButton.primary(
                label: 'Create Account',
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleSignup,
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

              // Link to Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: theme.textTheme.bodyLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                    },
                    child: Text(
                      'Sign In',
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
