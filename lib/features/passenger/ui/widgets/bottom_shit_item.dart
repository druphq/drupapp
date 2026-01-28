import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:flutter/material.dart';

class BottomSheetItem extends StatelessWidget {
  const BottomSheetItem({
    super.key,
    required this.assetName,
    required this.title,
    required this.subTitle,
    required this.onPressed,
    required this.margin,
  });
  final String assetName;
  final String title;
  final String subTitle;
  final Function() onPressed;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Corners.hMd),
        color: context.colorScheme.surface,
      ),
      margin: margin,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
        onTap: () {
          onPressed.call();
        },
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 15,
          child: ClipOval(child: Image.asset(assetName)),
        ),
        title: Text(
          title,
          style: TextStyles.h1.copyWith(
            color: context.colorScheme.onPrimary,
            fontSize: FontSizes.s16,
          ),
        ),
        subtitle: Text(
          subTitle,
          style: TextStyles.h4.copyWith(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.5),
            overflow: TextOverflow.ellipsis,
            fontSize: FontSizes.s14,
          ),
        ),
      ),
    );
  }
}
