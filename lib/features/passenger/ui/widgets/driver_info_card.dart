import 'package:drup/features/passenger/model/model.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({super.key, this.bookedRide});
  final BookedRide? bookedRide;

  @override
  Widget build(BuildContext context) {
    final driverInfo = bookedRide?.driver;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Corners.lg),
        border: Border.all(color: AppColors.grey50),
      ),
      padding: EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.black.withValues(alpha: 0.1),
            backgroundImage: driverInfo != null
                ? driverInfo.profilePhoto.isNotEmptyOrNull
                      ? AssetImage(AppAssets.privacyIcon)
                      : NetworkImage(driverInfo.profilePhoto ?? '')
                : null,
          ),
          Gap(12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    driverInfo != null
                        ? Text(
                            driverInfo.firstName,
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onAccent,
                            ),
                          )
                        : _buildBlurWidget(),
                    driverInfo != null
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent),
                              borderRadius: BorderRadius.circular(Corners.sm),
                              color: AppColors.grey50,
                            ),
                            child: Text(
                              'ABC-123-XY',
                              style: TextStyles.t2.copyWith(
                                fontSize: FontSizes.s11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : _buildBlurWidget(),
                  ],
                ),
                Gap(4.0),

                Text(
                  'Arriving in ${formatRelativeDateTime(bookedRide?.scheduledTime ?? DateTime.now())}',
                  textAlign: TextAlign.center,
                  style: TextStyles.t2.copyWith(
                    fontSize: FontSizes.s14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurWidget({double? width}) {
    return Container(
      height: 18,
      width: width ?? 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
