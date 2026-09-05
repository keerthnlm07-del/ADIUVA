import 'package:flutter/material.dart';
import '../theme/adiuva_spacing.dart';
import '../theme/adiuva_radius.dart';
import '../theme/adiuva_elevation.dart';

/// ADIUVA Reusable Accessible Card Component
/// 
/// Guarantees:
/// - Semantic accessibility labeling
/// - Interactive touch targets (minimum 56dp) when `onTap` is provided
/// - High contrast border outline support across light, dark, and high contrast themes
class AdiuvaCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;

  const AdiuvaCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;

    final effectiveRadius = borderRadius ??
        (cardTheme.shape is RoundedRectangleBorder
            ? (cardTheme.shape as RoundedRectangleBorder).borderRadius
            : AdiuvaRadius.borderRadiusLg);

    final effectiveBorder = borderSide ??
        (cardTheme.shape is RoundedRectangleBorder
            ? (cardTheme.shape as RoundedRectangleBorder).side
            : BorderSide.none);

    Widget cardChild = Padding(
      padding: padding ?? AdiuvaSpacing.paddingLg,
      child: child,
    );

    if (onTap != null) {
      cardChild = ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AdiuvaSpacing.minTouchTarget,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius is BorderRadius ? effectiveRadius : null,
          child: cardChild,
        ),
      );
    }

    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      label: semanticLabel,
      hint: semanticHint,
      child: Material(
        color: backgroundColor ?? cardTheme.color ?? theme.colorScheme.surface,
        elevation: elevation ?? cardTheme.elevation ?? AdiuvaElevation.level1,
        shape: RoundedRectangleBorder(
          borderRadius: effectiveRadius,
          side: effectiveBorder,
        ),
        clipBehavior: Clip.antiAlias,
        child: cardChild,
      ),
    );
  }
}
