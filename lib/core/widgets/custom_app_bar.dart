import 'package:flutter/material.dart';
import '../theme/adiuva_spacing.dart';

/// ADIUVA Reusable Accessible App Bar Component
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBackButton && canPop) {
      leadingWidget = Semantics(
        label: 'Back',
        button: true,
        child: SizedBox(
          width: AdiuvaSpacing.minTouchTarget,
          height: AdiuvaSpacing.minTouchTarget,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      leading: leadingWidget,
      actions: actions,
      bottom: bottom,
    );
  }
}
