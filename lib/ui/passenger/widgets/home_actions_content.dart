import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HomeActionsContent extends StatelessWidget {
  const HomeActionsContent({super.key, this.onWhereToTap});
  final VoidCallback? onWhereToTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gap(20),
        Text(
          AppStrings.scheduleRideTxt,
          textAlign: TextAlign.center,
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const Gap(20),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Corners.hMd),
            color: AppColors.surface,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListTile(
            minTileHeight: Sizes.tfieldHeight,
            onTap: onWhereToTap,
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.greyStrong, width: 2),
                ),
              ),
            ),
            minLeadingWidth: 2,
            title: Text(
              AppStrings.whereToTxt,
              style: TextStyles.t2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: FontSizes.s17,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
