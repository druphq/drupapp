import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/ui/widgets/driver_info_card.dart';
import 'package:drup/features/passenger/ui/widgets/location_dot_widget.dart';
import 'package:drup/features/passenger/ui/widgets/ride_map_widget.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RideDetailBottomsheet extends StatelessWidget {
  const RideDetailBottomsheet({super.key, required this.bookedRide});
  final BookedRide? bookedRide;

  @override
  Widget build(BuildContext context) {
    if (bookedRide == null) {
      return SizedBox.shrink();
    }

    final ride = bookedRide!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Corners.lg),
          topRight: Radius.circular(Corners.lg),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'Ride Booked',
            textAlign: TextAlign.center,
            style: TextStyles.t1.copyWith(
              fontSize: FontSizes.s24,
              fontWeight: FontWeight.w700,
              color: AppColors.onAccent,
            ),
          ),
          Gap(8),
          Text(
            'Driver will be arriving in ${formatRelativeDateTime(ride.scheduledTime ?? DateTime.now())}',
            textAlign: TextAlign.center,
            style: TextStyles.t2.copyWith(
              fontSize: FontSizes.s14,
              color: AppColors.textSecondary,
            ),
          ),
          Gap(32),

          // Trip Details
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Corners.md),
              border: Border.all(color: AppColors.greyStrong),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Details',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onAccent,
                  ),
                ),
                Gap(4.0),
                RichText(
                  text: TextSpan(
                    text: 'Scheduled for ',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: formatDate(ride.scheduledTime ?? DateTime.now()),
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s14,
                          color: AppColors.onAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap(12),
                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.center,
                //   children: [
                //     LocationDotWidget(
                //       bgColor: AppColors.green400,
                //       isActive: true,
                //       size: 12,
                //     ),
                //     Gap(12),
                //     Expanded(
                //       child: Column(
                //         mainAxisSize: MainAxisSize.min,
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text(
                //             'Pickup',
                //             style: TextStyles.t2.copyWith(
                //               fontSize: FontSizes.s14,
                //               color: AppColors.textSecondary,
                //               height: 1.4,
                //             ),
                //           ),
                //           Gap(4.0),
                //           Text(
                //             ride.pickup.name,
                //             style: TextStyles.t2.copyWith(
                //               fontSize: FontSizes.s16,
                //               color: AppColors.onAccent,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),
                // Gap(20),
                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     LocationDotWidget(
                //       bgColor: AppColors.accent,
                //       isActive: true,
                //       size: 12,
                //     ),
                //     Gap(12),
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Text(
                //             'Dropoff',
                //             style: TextStyles.t2.copyWith(
                //               fontSize: FontSizes.s14,
                //               color: AppColors.textSecondary,
                //             ),
                //           ),
                //           Gap(5.0),
                //           Text(
                //             ride.dropoff.name,
                //             style: TextStyles.t2.copyWith(
                //               fontSize: FontSizes.s16,
                //               color: AppColors.onAccent,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),
                RideMapWidget(ride: ride),
                Gap(16),
                Divider(color: AppColors.greyStrong),
                Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Fare',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent,
                      ),
                    ),
                    Text(
                      '₦${formatThousand(ride.fare.totalFare)}',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (ride.driver != null) ...[
            DriverInfoCard(driver: ride.driver!),
          ] else ...[
            Gap(16),
            Text(
              'Driver details will be available once a driver is assigned to your ride.',
              textAlign: TextAlign.center,
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s14,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          Gap(24),

          // Make Payment Button
          CustomButton(text: 'Make Payment', onPressed: () {}),
        ],
      ),
    );
  }
}
