import 'package:drup/core/widgets/dotted_line_widget.dart';
import 'package:drup/features/passenger/ui/widgets/location_dot_widget.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class LocationMapWidget extends StatelessWidget {
  const LocationMapWidget({
    super.key,
    this.pickoffAddress = '123 Main St, Lagos',
    this.dropoffAddress = '456 Elm St, Lagos',
  });
  final String pickoffAddress;
  final String dropoffAddress;

  static const double _dotSize = 16;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dot column with vertical divider connecting them
          SizedBox(
            width: _dotSize,
            child: Column(
              children: [
                const Gap(2),
                LocationDotWidget(
                  bgColor: AppColors.green400,
                  isActive: true,
                  size: _dotSize,
                ),
                Expanded(
                  child: CustomPaint(
                    painter: DottedLinePainter(color: AppColors.textSecondary),
                  ),
                ),
                LocationDotWidget(
                  bgColor: AppColors.red400,
                  isActive: true,
                  size: _dotSize,
                ),
              ],
            ),
          ),
          const Gap(16),
          // Text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: TextStyles.t2.copyWith(
                        fontSize: 14,
                        color: AppColors.white,
                        height: 1.4,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      pickoffAddress,
                      style: TextStyles.t2.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const Gap(30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dropoffAddress,
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Drop-off',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s14,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
