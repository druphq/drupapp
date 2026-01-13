import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.hint,
    this.controller,
    this.borderRadius,
    this.validator,
    this.style,
  });
  final String hint;
  final double? borderRadius;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: validator,
          style: style ?? TextStyles.h4,
          maxLength: 11,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9]')),
            FilteringTextInputFormatter.deny(RegExp(r'^\+')),
            FilteringTextInputFormatter.deny(RegExp(r'^234')),
            LengthLimitingTextInputFormatter(12),
            FilteringTextInputFormatter.digitsOnly,
          ],
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.filledColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Gap(20.0),
                Container(
                  clipBehavior: Clip.hardEdge,
                  height: 40.0,
                  width: 25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Corners.md),
                  ),
                  child: Image.asset(AppAssets.ngFlag.assetName),
                ),
                const Gap(5.0),
                Text(AppStrings.ngCode, style: TextStyles.h4),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 40.0,
                    child: VerticalDivider(color: AppColors.grey),
                  ),
                ),
                const Gap(5.0),
              ],
            ),
            hintText: hint,
            hintStyle: (style ?? TextStyles.h4).copyWith(color: Colors.grey),
            disabledBorder: const OutlineInputBorder(borderSide: BorderSide()),
            border: OutlineInputBorder(
              borderSide: const BorderSide(
                width: 1.5,
                color: AppColors.filledColor,
              ),
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                width: 1.5,
                color: AppColors.filledColor,
              ),
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                width: 1.5,
                color: AppColors.filledColor,
              ),
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(width: 1.5, color: Colors.red),
              borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
            ),
          ),
        ),
      ],
    );
  }
}
