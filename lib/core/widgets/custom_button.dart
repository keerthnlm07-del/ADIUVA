import 'package:flutter/material.dart';
import '../theme/adiuva_colors.dart';
import '../theme/adiuva_spacing.dart';
import '../theme/adiuva_radius.dart';
import '../theme/adiuva_elevation.dart';

/// Button Variant Types for ADIUVA Design System
enum AdiuvaButtonVariant {
  primary,
  secondary,
  voiceAction,
  outlined,
  ghost,
}

/// ADIUVA Reusable Accessible Button Component
/// 
/// Guarantees:
/// - Minimum interactive touch target height of 56dp
/// - Accessible contrast across light, dark, and high-contrast themes
/// - Semantic labels and hints for TalkBack / Screen Readers
/// - Voice-action Amber styling when required
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AdiuvaButtonVariant variant;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final String? semanticHint;
  final double? width;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AdiuvaButtonVariant.primary,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticHint,
    this.width,
  });

  /// Factory constructor for Primary Verdant Teal Button
  factory CustomButton.primary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    String? semanticHint,
    double? width,
  }) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      variant: AdiuvaButtonVariant.primary,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      semanticHint: semanticHint,
      width: width,
    );
  }

  /// Factory constructor for Secondary Container Button
  factory CustomButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    String? semanticHint,
    double? width,
  }) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      variant: AdiuvaButtonVariant.secondary,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      semanticHint: semanticHint,
      width: width,
    );
  }

  /// Factory constructor for Voice / Sand Action Button
  factory CustomButton.voiceAction({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    String? semanticHint,
    double? width,
  }) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      variant: AdiuvaButtonVariant.voiceAction,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      semanticHint: semanticHint,
      width: width,
    );
  }

  /// Factory constructor for Outlined Border Button
  factory CustomButton.outlined({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    String? semanticHint,
    double? width,
  }) {
    return CustomButton(
      label: label,
      onPressed: onPressed,
      variant: AdiuvaButtonVariant.outlined,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      semanticHint: semanticHint,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = theme.brightness == Brightness.light &&
            theme.colorScheme.primary == AdiuvaColors.hcLightPrimary ||
        theme.brightness == Brightness.dark &&
            theme.colorScheme.primary == AdiuvaColors.hcDarkPrimary;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AdiuvaButtonVariant.primary:
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = theme.colorScheme.onPrimary;
        break;
      case AdiuvaButtonVariant.secondary:
        backgroundColor = theme.colorScheme.primaryContainer;
        foregroundColor = theme.colorScheme.onPrimaryContainer;
        break;
      case AdiuvaButtonVariant.voiceAction:
        backgroundColor = AdiuvaColors.voiceAmber;
        foregroundColor = AdiuvaColors.onVoiceContainer;
        break;
      case AdiuvaButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.colorScheme.primary;
        borderSide = BorderSide(
          color: theme.colorScheme.primary,
          width: isHighContrast ? AdiuvaElevation.hcBorderThick : 1.5,
        );
        break;
      case AdiuvaButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.colorScheme.primary;
        break;
    }

    if (isHighContrast && variant != AdiuvaButtonVariant.outlined) {
      borderSide = BorderSide(
        color: theme.colorScheme.onSurface,
        width: AdiuvaElevation.hcBorderThick,
      );
    }

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: AdiuvaSpacing.md),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 24, color: foregroundColor),
          const SizedBox(width: AdiuvaSpacing.md),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AdiuvaSpacing.md),
          Icon(trailingIcon, size: 24, color: foregroundColor),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      hint: semanticHint,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AdiuvaSpacing.minTouchTarget,
          minWidth: width ?? 88.0,
        ),
        child: SizedBox(
          width: width,
          height: AdiuvaSpacing.minTouchTarget,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: variant == AdiuvaButtonVariant.ghost ||
                      variant == AdiuvaButtonVariant.outlined
                  ? 0
                  : AdiuvaElevation.level1,
              shape: RoundedRectangleBorder(
                borderRadius: isHighContrast
                    ? AdiuvaRadius.borderRadiusSm
                    : AdiuvaRadius.borderRadiusMd,
                side: borderSide,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AdiuvaSpacing.xl,
                vertical: AdiuvaSpacing.md,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Alias for CustomButton as AdiuvaButton
typedef AdiuvaButton = CustomButton;
