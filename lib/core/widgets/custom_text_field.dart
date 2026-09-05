import 'package:flutter/material.dart';
import '../theme/adiuva_spacing.dart';
import '../theme/adiuva_radius.dart';
import '../theme/adiuva_elevation.dart';

/// ADIUVA Reusable Accessible Text Field Component
/// 
/// Features:
/// - Guaranteed minimum touch target height of 56dp
/// - High legibility font sizes and strong border contrast
/// - Screen reader semantics for labels, hints, and error messages
/// - Password visibility toggle button with accessible hit target
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = theme.inputDecorationTheme.border?.borderSide.width ==
        AdiuvaElevation.hcBorderThick;

    Widget? suffixWidget = widget.suffixIcon;

    if (widget.isPassword) {
      suffixWidget = Semantics(
        label: _obscureText ? 'Show password' : 'Hide password',
        button: true,
        child: SizedBox(
          width: AdiuvaSpacing.minTouchTarget,
          height: AdiuvaSpacing.minTouchTarget,
          child: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      );
    }

    return Semantics(
      label: widget.label,
      hint: widget.hintText,
      textField: true,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AdiuvaSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AdiuvaSpacing.minTouchTarget,
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              obscureText: widget.isPassword ? _obscureText : false,
              enabled: widget.enabled,
              onChanged: widget.onChanged,
              validator: widget.validator,
              textInputAction: widget.textInputAction,
              onFieldSubmitted: widget.onSubmitted,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hintText,
                helperText: widget.helperText,
                errorText: widget.errorText,
                prefixIcon: widget.prefixIcon,
                suffixIcon: suffixWidget,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AdiuvaSpacing.lg,
                  vertical: AdiuvaSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: isHighContrast
                      ? AdiuvaRadius.borderRadiusSm
                      : AdiuvaRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alias for CustomTextField as AdiuvaTextField
typedef AdiuvaTextField = CustomTextField;
