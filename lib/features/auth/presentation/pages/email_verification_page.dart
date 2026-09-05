import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/adiuva_spacing.dart';
import '../../../../core/widgets/accessibility_scaffold.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/error_dialog.dart';
import '../../../../config/routes/app_routes.dart';

/// ADIUVA Email Verification Page
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Timer? _timer;
  bool _isSending = false;
  bool _isChecking = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _sendInitialVerificationEmail();
    _startPeriodicVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendInitialVerificationEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          _statusMessage = 'Verification email sent to ${user.email}.';
        });
        AccessibilityScaffold.announce(_statusMessage!);
      }
    } catch (e) {
      // Ignore if sent recently or rate limited
    }
  }

  void _startPeriodicVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkEmailVerified();
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
    });

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        if (_firebaseAuth.currentUser?.emailVerified ?? false) {
          _timer?.cancel();
          if (!mounted) return;
          AccessibilityScaffold.announce('Email verified successfully! Navigating to home screen.');
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      }
    } catch (e) {
      // Quiet fail during background poll
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSending = true;
    });

    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        setState(() {
          _statusMessage = 'Verification email resent to ${user.email}.';
        });
        if (!mounted) return;
        AccessibilityScaffold.announce('Verification email resent. Please check your inbox.');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorDialog.show(
        context,
        title: 'Resend Failed',
        message: 'Could not send verification email: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _firebaseAuth.currentUser;
    final userEmail = user?.email ?? 'your email';

    return AccessibilityScaffold(
      pageTitle: 'Email Verification Screen',
      appBar: const CustomAppBar(
        title: 'Verify Email',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdiuvaSpacing.gapLg,
            Container(
              width: 90,
              height: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            AdiuvaSpacing.gapXl,
            Text(
              'Verify Your Email Address',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapMd,
            Text(
              'We sent a verification link to:\n$userEmail',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapMd,
            Text(
              'Please click the link in your email to verify your account and continue.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AdiuvaSpacing.gapXxl,

            if (_statusMessage != null) ...[
              Container(
                padding: AdiuvaSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              AdiuvaSpacing.gapLg,
            ],

            // Manual Check Action Button
            CustomButton.primary(
              label: "I've Verified My Email",
              isLoading: _isChecking,
              leadingIcon: Icons.refresh_outlined,
              onPressed: _checkEmailVerified,
            ),
            AdiuvaSpacing.gapMd,

            // Resend Action Button
            CustomButton.secondary(
              label: 'Resend Verification Email',
              isLoading: _isSending,
              leadingIcon: Icons.send_outlined,
              onPressed: _isSending ? null : _resendVerificationEmail,
            ),
            AdiuvaSpacing.gapXl,

            TextButton(
              onPressed: () async {
                _timer?.cancel();
                final navigator = Navigator.of(context);
                await _firebaseAuth.signOut();
                navigator.pushReplacementNamed(AppRoutes.login);
              },
              child: Text(
                'Back to Sign In',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
