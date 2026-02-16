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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: dots + dotted line
          SizedBox(
            width: 12,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: LocationDotWidget(
                    bgColor: AppColors.green400,
                    isActive: true,
                    size: 12,
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _DottedLinePainter(color: AppColors.textSecondary),
                    child: SizedBox(width: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: LocationDotWidget(
                    bgColor: AppColors.red100,
                    isActive: true,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
          Gap(12),

          // Right side: pickup & dropoff info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup section
                Text(
                  'Pickup Address',
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
                Gap(4.0),

                Gap(30),
                // Dropoff section
                Text(
                  ride.dropoff.name,
                  style: TextStyles.t2.copyWith(
                    fontSize: FontSizes.s16,
                    color: AppColors.onAccent,
                  ),
                ),
                Gap(5.0),

                Text(
                  'Drop-off Address',
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
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  const _DottedLinePainter({required this.color});

  static const double _strokeWidth = 1.5;
  static const double _dashHeight = 4.0;
  static const double _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    double currentY = 0;

    while (currentY < size.height) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - _strokeWidth / 2,
            currentY,
            _strokeWidth,
            _dashHeight,
          ),
          Radius.circular(_strokeWidth / 2),
        ),
        paint,
      );
      currentY += _dashHeight + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
