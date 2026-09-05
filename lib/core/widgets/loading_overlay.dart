import 'package:flutter/material.dart';
import '../theme/adiuva_spacing.dart';
import '../theme/adiuva_radius.dart';

/// ADIUVA Accessible Loading Overlay Component
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? loadingText;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.loadingText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        child,
        if (isLoading)
          Semantics(
            label: loadingText ?? 'Loading, please wait...',
            container: true,
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: AdiuvaSpacing.paddingXl,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AdiuvaRadius.borderRadiusLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      if (loadingText != null) ...[
                        const SizedBox(height: AdiuvaSpacing.lg),
                        Text(
                          loadingText!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
