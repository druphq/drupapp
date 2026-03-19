import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RideCardWidget extends StatelessWidget {
  const RideCardWidget({
    super.key,
    required this.rideSlot,
    required this.onTap,
    this.isSelected = false,
    this.isIndividual = false,
  });

  final bool isSelected;
  final bool isIndividual;
  final RideSlot rideSlot;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.c8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(Corners.c8),
            border: Border.all(
              color: isSelected ? AppColors.greyStrong : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: isIndividual
                    ? null
                    : BoxDecoration(
                        color: AppColors.green400,
                        borderRadius: BorderRadius.circular(Corners.c10),
                      ),
                padding: EdgeInsets.only(left: 16.0, right: 8.0, top: 16.0),
                width: 99,
                child: Image.asset(
                  AppAssets.carIcon,
                  height: 30,
                  width: 99,
                  fit: BoxFit.contain,
                ),
              ),
              Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatRideType(rideSlot.rideType ?? ''),
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onAccent,
                      ),
                    ),
                    Gap(2),
                    Row(
                      children: [
                        ...List.generate(rideSlot.totalSeats ?? 0, (index) {
                          final isFilled =
                              index < (rideSlot.existingRides.length);

                          return Icon(
                            Icons.person_outline,
                            size: 18,
                            color: isFilled
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₦${formatThousand(rideSlot.price ?? 0.0)}',
                    style: TextStyles.t1.copyWith(
                      fontSize: FontSizes.s18,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  Text(
                    '${rideSlot.luggageAllowance}kg',
                    style: TextStyles.body1.copyWith(fontSize: FontSizes.s16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
