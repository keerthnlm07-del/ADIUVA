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

/// ADIUVA Forgot Password Page
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AccessibilityScaffold.announce('Please enter a valid email address.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resetPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (authProvider.errorMessage != null) {
      AccessibilityScaffold.announce('Password reset error: ${authProvider.errorMessage}');
      ErrorDialog.show(
        context,
        title: 'Reset Failed',
        message: authProvider.errorMessage!,
      );
    } else {
      setState(() {
        _emailSent = true;
      });
      AccessibilityScaffold.announce(
        'Password reset email sent to ${_emailController.text.trim()}. Check your inbox.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return AccessibilityScaffold(
      pageTitle: 'Forgot Password Screen',
      appBar: const CustomAppBar(
        title: 'Reset Password',
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdiuvaSpacing.gapLg,
              Text(
                'Reset Your Password',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapSm,
              Text(
                'Enter the email associated with your ADIUVA account to receive a password reset link.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              AdiuvaSpacing.gapXxl,

              if (_emailSent) ...[
                Container(
                  padding: AdiuvaSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 32),
                      const SizedBox(width: AdiuvaSpacing.md),
                      Expanded(
                        child: Text(
                          'Password reset email sent to ${_emailController.text.trim()}. Please check your inbox.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AdiuvaSpacing.gapXxl,
                CustomButton.primary(
                  label: 'Back to Sign In',
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                ),
              ] else ...[
                CustomTextField(
                  label: 'Email Address',
                  hintText: 'name@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleResetPassword(),
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
                AdiuvaSpacing.gapXxl,

                CustomButton.primary(
                  label: 'Send Reset Link',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleResetPassword,
                ),
                AdiuvaSpacing.gapLg,

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel and return to Sign In',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
