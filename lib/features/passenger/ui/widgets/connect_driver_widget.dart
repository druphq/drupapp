import 'package:drup/resources/app_assets.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ConnectDriverWidget extends StatelessWidget {
  const ConnectDriverWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connecting to a driver',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent,
                      ),
                    ),
                    // Gap(4),
                    Text(
                      'A driver will be assigned to you once your order is confirmed',
                      textAlign: TextAlign.start,
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.red400.withOpacity(0.1),
                  border: Border.all(color: AppColors.red400),
                ),
                padding: EdgeInsets.all(4),
                child: Icon(Icons.drive_eta, color: AppColors.red400, size: 24),
              ),
            ],
          ),

          Gap(30.0),

          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: Image.asset(
                      AppAssets.driverIcon,
                      width: 70,
                      height: 70,
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Image.asset(
                      AppAssets.verifiedIcon,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ],
              ),
              Gap(10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Ifeanyi osita',
                    style: TextStyles.t1.copyWith(
                      fontSize: FontSizes.s16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onAccent,
                    ),
                  ),
                  Gap(3.0),

                  Text(
                    'Processing...',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s10,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  Gap(3.0),

                  Text(
                    '4.9 based on 264 ratings',
                    style: TextStyles.t2.copyWith(fontSize: FontSizes.s11),
                  ),
                ],
              ),
            ],
          ),

          Gap(30.0),

          LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            backgroundColor: AppColors.accent.withOpacity(0.2),
            minHeight: 6,
            value: 0.5,
            trackGap: 8.0,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
