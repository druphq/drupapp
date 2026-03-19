import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DriverMatchedWidget extends StatelessWidget {
  const DriverMatchedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
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
                      'Request  Accepted',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent,
                      ),
                    ),
                    // Gap(4),
                    Text(
                      'Gray Toyota Camry',
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

          Center(
            child: InkWell(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      Row(
                        children: [
                          Text(
                            'Driver Ifeanyi osita',
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onAccent,
                            ),
                          ),
                          //show plate number
                          Gap(10.0),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent),
                              borderRadius: BorderRadius.circular(Corners.c4),
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
                          ),
                        ],
                      ),
                      Gap(2.0),

                      Text(
                        'Arriving in 3 Days 1 Hour 45 Minutes',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s10,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      Gap(4.0),

                      Text(
                        '4.9 based on 264 ratings',
                        style: TextStyles.t2.copyWith(fontSize: FontSizes.s11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          CustomButton(text: 'Make Payment', onPressed: () {}),
        ],
      ),
    );
  }
}
