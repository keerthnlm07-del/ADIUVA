import 'package:flutter/material.dart';
import '../theme/adiuva_spacing.dart';
import '../theme/adiuva_radius.dart';
import 'custom_button.dart';

/// ADIUVA Accessible Error Dialog
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.buttonText = 'OK',
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      focused: true,
      label: '$title: $message',
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AdiuvaRadius.borderRadiusLg,
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 28),
            const SizedBox(width: AdiuvaSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          CustomButton.primary(
            label: buttonText,
            onPressed: () {
              Navigator.of(context).pop();
              if (onDismiss != null) {
                onDismiss!();
              }
            },
          ),
        ],
      ),
    );
  }
}
