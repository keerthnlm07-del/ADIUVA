import 'package:flutter/material.dart';
import '../theme/adiuva_colors.dart';
import '../theme/adiuva_spacing.dart';
import 'accessibility_scaffold.dart';

/// Reusable Icon-First Card / Button for ADIUVA Accessibility Dashboards.
///
/// Features:
/// - Dark navy glass/elevated container styling.
/// - Prominent vector icon (28–32dp) with vibrant accent background avatar.
/// - Minimal visible label (1–3 words).
/// - TalkBack / Accessibility Semantics (`Semantics` wrapper with button flag).
/// - Accessible touch target height (minimum 80dp).
class AdiuvaIconTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;
  final String? semanticLabel;
  final double? minHeight;
  final Color? customCardColor;
  final BorderSide? borderSide;

  const AdiuvaIconTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.semanticLabel,
    this.minHeight,
    this.customCardColor,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveSemanticLabel = semanticLabel ?? 'Open $title';

    final defaultBg = customCardColor ??
        (isDark
            ? AdiuvaColors.darkSurface
            : theme.colorScheme.surface);

    final effectiveBorder = borderSide ??
        BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        );

    return Semantics(
      container: true,
      button: true,
      enabled: true,
      label: effectiveSemanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AccessibilityScaffold.announce(effectiveSemanticLabel);
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: BoxConstraints(
              minHeight: minHeight ?? (subtitle != null ? 90 : 80),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AdiuvaSpacing.md,
              vertical: AdiuvaSpacing.md,
            ),
            decoration: BoxDecoration(
              color: defaultBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.fromBorderSide(effectiveBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
