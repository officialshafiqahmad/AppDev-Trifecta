import 'package:flutter/material.dart';
import 'package:trifecta/core/theme/theme_ext.dart';

/// Standard application text input component ensuring identical styling across all screens.
/// Hard law: No ad-hoc InputDecoration blocks inside feature views.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sizes = context.sizes;
    final text = context.text;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      borderSide: BorderSide(color: colors.border),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      borderSide: BorderSide(color: colors.primary, width: 1.5),
    );

    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(sizes.radiusMd),
      borderSide: BorderSide(color: colors.error, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: text.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: sizes.xs + 2),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLines: maxLines,
          minLines: minLines,
          focusNode: focusNode,
          autofocus: autofocus,
          style: text.bodyMd.copyWith(color: colors.textPrimary),
          cursorColor: colors.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: text.bodyMd.copyWith(color: colors.textTertiary),
            helperText: helperText,
            helperStyle: text.caption.copyWith(color: colors.textSecondary),
            errorText: errorText,
            errorStyle: text.caption.copyWith(color: colors.error),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? colors.surface : colors.surfaceVariant,
            contentPadding: EdgeInsets.symmetric(
              horizontal: sizes.lg,
              vertical: sizes.md + 2,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: focusedBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder,
          ),
        ),
      ],
    );
  }
}
