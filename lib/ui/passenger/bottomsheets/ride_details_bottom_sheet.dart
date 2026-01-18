import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/ui/passenger/widgets/location_dot_widget.dart';
import 'package:drup/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RideDetailsBottomSheet extends StatelessWidget {
  final String pickupLocation;
  final String destinationLocation;
  final double? rideAmount;
  final VoidCallback? onScheduleRide;

  const RideDetailsBottomSheet({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    this.rideAmount = 6000,
    required this.onScheduleRide,
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
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₦${rideAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyles.t1.copyWith(
                  fontSize: FontSizes.s24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Cancel',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(20),

        // Pickup Location
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationDotWidget(bgColor: AppColors.green400, isActive: true),
            Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s12,
                      color: AppColors.surface,
                    ),
                  ),
                  Gap(4),
                  Text(
                    pickupLocation,
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap(16),

        // Destination Location
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationDotWidget(bgColor: AppColors.accent, isActive: true),
            Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destination',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s12,
                      color: AppColors.surface,
                    ),
                  ),
                  Gap(4),
                  Text(
                    destinationLocation,
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap(30),

        // Schedule Ride Button
        CustomButton(
          text: 'Schedule Ride',
          onPressed: rideAmount != null ? onScheduleRide : () {},
          isLoading: false,
        ),
      ],
    );
  }
}
