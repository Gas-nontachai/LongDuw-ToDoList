import 'package:flutter/material.dart';

/// A reusable form field styled by the application's input decoration theme.
/// Callers own controllers, localized text, validation, and submit behavior.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    onChanged: onChanged,
    validator: validator,
    enabled: enabled,
    obscureText: obscureText,
    autofocus: autofocus,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    onFieldSubmitted: onFieldSubmitted,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    ),
  );
}
