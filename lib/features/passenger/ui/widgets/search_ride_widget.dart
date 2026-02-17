import 'package:drup/core/animation/searching_ripple.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SearchRideWidget extends StatelessWidget {
  const SearchRideWidget({super.key, this.isSlotSelected = false});
  final bool isSlotSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Corners.lg),
          topRight: Radius.circular(Corners.lg),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(30.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSlotSelected
                            ? 'Booking your ride...'
                            : 'Searching for available rides...',
                        style: TextStyles.t1.copyWith(
                          fontSize: FontSizes.s18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onAccent,
                        ),
                      ),
                      // Gap(4),
                      Text(
                        isSlotSelected
                            ? 'Hold on, scheduling your ride...'
                            : 'Hold on lets search for available rides around you',
                        overflow: TextOverflow.ellipsis,
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
                  child: Icon(
                    Icons.drive_eta,
                    color: AppColors.red400,
                    size: 24,
                  ),
                ),
              ],
            ),

            Center(
              child: SearchingRipple(
                size: 180,
                primaryColor: AppColors.accent, // teal-ish outer rings
              ),
            ),
            Gap(MediaQuery.of(context).size.height * 0.06),
          ],
        ),
      ),
    );
  }
}
