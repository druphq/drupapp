import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/features/passenger/ui/widgets/driver_info_card.dart';
import 'package:drup/features/passenger/ui/widgets/ride_map_widget.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class RideDetailBottomsheet extends ConsumerWidget {
  const RideDetailBottomsheet({super.key, required this.bookedRide});
  final BookedRide? bookedRide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookedRide == null) {
      return SizedBox.shrink();
    }

    final ride = bookedRide!;
    final rideState = ref.watch(rideNotifierProvider);

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
          CustomButton(
            text: 'Make Payment',
            isLoading: rideState.isLoading,
            onPressed: () async {
              final result = await ref
                  .read(rideNotifierProvider.notifier)
                  .initializePayment(rideId: ride.id, paymentMethod: 'card');

              if (!context.mounted) return;

              if (result?.authorizationUrl != null) {
                context.push(
                  AppRoutes.paymentWebViewRoute,
                  extra: {
                    'authorizationUrl': result!.authorizationUrl!,
                    'onPaymentComplete': () async {
                      // Pop webview and navigate to ride details
                      context.pop();
                      await context.push(
                        AppRoutes.rideDetailsRoute,
                        extra: ride,
                      );

                      ref.read(rideNotifierProvider.notifier).clearRoute();
                    },
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to initialize payment. Please try again.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
