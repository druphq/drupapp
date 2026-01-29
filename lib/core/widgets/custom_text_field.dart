import 'package:drup/core/widgets/custom_input_borader.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/utils/extension.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.style,
    this.cornerRadius,
    this.prefixIcon,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.isEditable,
    this.outline,
    this.elevate,
    this.helperText,
    this.initialValue,
    this.maxLine,
    this.onChanged,
  });
  final TextEditingController? controller;
  final String hintText;
  final TextStyle? style;
  final double? cornerRadius;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextCapitalization? textCapitalization;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool? isEditable;
  final bool? elevate;
  final bool? outline;
  final String? helperText;
  final String? initialValue;
  final Function(String?)? onChanged;
  final int? maxLine;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: style ?? const TextStyle(fontSize: 16.0),
      keyboardType: TextInputType.text,
      autocorrect: false,
      initialValue: initialValue,
      maxLines: maxLine,
      validator: validator,
      decoration: InputDecoration(
        fillColor: AppColors.filledColor,
        filled: true,
        label: Row(
          children: [
            const SizedBox(width: 12),
            Text(hintText, style: style ?? const TextStyle(fontSize: 16)),
          ],
        ),
        prefix: const SizedBox(
          width: 10,
          child: Row(children: [SizedBox(width: 12)]),
        ),
        border: CustomInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(cornerRadius ?? 12.0),
        ),
        enabledBorder: CustomInputBorder(
          borderRadius: BorderRadius.circular(cornerRadius ?? 12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: CustomInputBorder(
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          borderRadius: BorderRadius.circular(cornerRadius ?? 12.0),
        ),
        hintText: hintText,
        hintStyle: style?.copyWith(color: context.colorScheme.onSurface),
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
    );
  }
}
