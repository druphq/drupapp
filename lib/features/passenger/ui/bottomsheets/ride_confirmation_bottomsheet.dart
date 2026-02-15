import 'package:drup/core/widgets/custom_shimmer_widget.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/ui/widgets/location_map_widget.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

class RideConfirmationBottomSheet extends StatelessWidget {
  final String pickupLocation;
  final String destinationLocation;
  final VehicleEstimate? estimate;
  final bool isLoading;
  final VoidCallback? onScheduleRide;
  final VoidCallback? onEditRide;

  const RideConfirmationBottomSheet({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    this.estimate,
    this.isLoading = false,
    this.onScheduleRide,
    this.onEditRide,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap(30),
        // Title
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              isLoading && estimate == null
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.withOpacity(0.5),
                      highlightColor: Colors.grey.withOpacity(0.8),
                      child: Container(
                        width: 100,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.accent,
                        ),
                      ),
                    )
                  : Text(
                      '₦${formatThousand(estimate?.fare.totalFare ?? 0)}',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),

              if (estimate != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${formatDistance(estimate?.distanceKm ?? 0)}, ${formatDuration(estimate?.durationMinutes ?? 0)}',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomShimmerWidget(
                      child: Container(
                        width: 50,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    Gap(5),
                    CustomShimmerWidget(
                      child: Container(
                        width: 50,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Gap(20),

        LocationMapWidget(
          pickoffAddress: pickupLocation,
          dropoffAddress: destinationLocation,
        ),

        // Pickup Location
        // Row(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     LocationDotWidget(bgColor: AppColors.green400, isActive: true),
        //     Gap(16),
        //     Expanded(
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Text(
        //             'Pickup',
        //             style: TextStyles.t2.copyWith(
        //               fontSize: FontSizes.s14,
        //               color: AppColors.surface,
        //             ),
        //           ),
        //           Gap(4),
        //           Text(
        //             pickupLocation,
        //             style: TextStyles.t2.copyWith(
        //               fontSize: FontSizes.s18,
        //               fontWeight: FontWeight.w700,
        //               color: AppColors.white,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
        // Gap(16),

        // // Drop-off Location
        // Row(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     LocationDotWidget(bgColor: AppColors.accentLight, isActive: true),
        //     Gap(16),
        //     Expanded(
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Text(
        //             'Drop-off',
        //             style: TextStyles.t2.copyWith(
        //               fontSize: FontSizes.s14,
        //               color: AppColors.surface,
        //             ),
        //           ),
        //           Gap(4),
        //           Text(
        //             destinationLocation,
        //             style: TextStyles.t2.copyWith(
        //               fontSize: FontSizes.s18,
        //               fontWeight: FontWeight.w700,
        //               color: AppColors.white,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
        Gap(30),

        // Schedule Ride Button
        CustomButton(
          text: 'Schedule Ride',
          onPressed: estimate != null ? onScheduleRide : () {},
          backgroundColor: estimate != null
              ? AppColors.white
              : AppColors.white.withOpacity(0.2),
          textStyle: TextStyles.btnStyle.copyWith(color: AppColors.onAccent),
          icon: ImageIcon(
            AssetImage(AppAssets.scheduleIcon),
            size: 20,
            color: AppColors.onAccent,
          ),
        ),
      ],
    );
  }
}
