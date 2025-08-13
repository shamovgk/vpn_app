// lib/ui/widgets/atoms/app_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vpn_app/core/extensions/context_ext.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;

  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  final bool enabled;
  final bool readOnly;
  final bool obscureText;

  final int? maxLines;
  final int? minLines;

  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingPressed,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.autofillHints,
    this.onSubmitted,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    final baseBorder = OutlineInputBorder(
      borderRadius: t.radii.brSm,
      borderSide: BorderSide(color: c.borderMuted, width: 1),
    );

    final decoration = InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: t.typography.bodySm.copyWith(color: c.textMuted),
      hintStyle: t.typography.bodySm.copyWith(color: c.textMuted),
      filled: true,
      fillColor: c.bgLight,
      contentPadding: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: t.spacing.sm,
      ),
      prefixIcon: leadingIcon != null ? Icon(leadingIcon, color: c.textMuted) : null,
      suffixIcon: trailingIcon != null
          ? IconButton(
              onPressed: onTrailingPressed,
              icon: Icon(trailingIcon, color: c.textMuted),
            )
          : null,
      border: baseBorder,
      enabledBorder: baseBorder,
      disabledBorder: OutlineInputBorder(
        borderRadius: t.radii.brSm,
        borderSide: BorderSide(color: c.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: t.radii.brSm,
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: t.radii.brSm,
        borderSide: BorderSide(color: c.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: t.radii.brSm,
        borderSide: BorderSide(color: c.danger, width: 1.5),
      ),
    );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? 1 : minLines,
      style: t.typography.body.copyWith(color: c.text),
      decoration: decoration,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      onChanged: onChanged,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
    );
  }
}
