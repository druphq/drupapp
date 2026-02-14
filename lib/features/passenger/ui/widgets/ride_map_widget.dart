import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/ui/widgets/location_dot_widget.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RideMapWidget extends StatelessWidget {
  const RideMapWidget({super.key, required this.ride});
  final BookedRide ride;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationDotWidget(
              bgColor: AppColors.green400,
              isActive: true,
              size: 12,
            ),
            Gap(12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  Gap(4.0),
                  Text(
                    ride.pickup.name,
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s16,
                      color: AppColors.onAccent,
                    ),
                  ),
                  Gap(4.0),
                  RichText(
                    text: TextSpan(
                      text: 'Pickup window: ',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s14,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: formatTime(
                            ride.pickupWindow?.start ?? DateTime.now(),
                          ),
                          style: TextStyles.t2.copyWith(
                            fontSize: FontSizes.s14,
                            color: AppColors.onAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' - ${formatTime(ride.pickupWindow?.end ?? DateTime.now())}',
                          style: TextStyles.t2.copyWith(
                            fontSize: FontSizes.s14,
                            color: AppColors.onAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Gap(20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationDotWidget(
              bgColor: AppColors.accent,
              isActive: true,
              size: 12,
            ),
            Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dropoff',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Gap(5.0),
                  Text(
                    ride.dropoff.name,
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s16,
                      color: AppColors.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
