import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/provider/ride_notifier.dart';
import 'package:drup/features/passenger/ui/widgets/driver_info_card.dart';
import 'package:drup/features/passenger/ui/widgets/ride_map_widget.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
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

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Corners.lg),
            topRight: Radius.circular(Corners.lg),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Gap(60.0),
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
            Expanded(
              child: ListView(
                children: [
                  if (ride.driver != null) Gap(16),

                  if (ride.driver != null) DriverInfoCard(bookedRide: ride),

                  Gap(10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(Corners.md),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Driver\'s detail will appear once a driver is assigned to your ride.',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Gap(10),
                  // Trip Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'Ride Type:',
                              style: TextStyles.h2.copyWith(
                                fontSize: FontSizes.s14,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      ' ${ride.rideType.capitalizeFirstChar()}',
                                  style: TextStyles.t2.copyWith(
                                    fontSize: FontSizes.s18,
                                    color: AppColors.onAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.drive_eta,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          Gap(4.0),
                          Text(
                            ride.vehicleType.capitalizeFirstChar(),
                            style: TextStyles.t2.copyWith(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Gap(4.0),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: ride.rideNumber),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'Ref: ${ride.rideNumber}',
                              style: TextStyles.t2.copyWith(
                                fontSize: FontSizes.s14,
                                color: AppColors.onAccent,
                              ),
                            ),
                            Gap(4.0),
                            Icon(
                              Icons.copy,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      Gap(10),
                      RideMapWidget(ride: ride),

                      Gap(20),
                      CustomButton(
                        text: 'Get help with ride',
                        onPressed: () {},
                        backgroundColor: AppColors.grey50,
                        textStyle: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s16,
                          color: AppColors.onAccent,
                        ),
                      ),

                      Gap(10),

                      // Padding(
                      //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                      //   child: Divider(color: AppColors.grey50),
                      // ),
                      Text(
                        'Payment',
                        style: TextStyles.t1.copyWith(
                          fontSize: FontSizes.s16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onAccent,
                        ),
                      ),

                      Gap(12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booking Fees',
                            style: TextStyles.body1.copyWith(
                              fontSize: FontSizes.s16,
                              color: AppColors.onAccent,
                            ),
                          ),
                          Text(
                            '₦${formatThousand(ride.fare.serviceFee)}',
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ride Fees',
                            style: TextStyles.body1.copyWith(
                              fontSize: FontSizes.s16,
                              color: AppColors.onAccent,
                            ),
                          ),
                          Text(
                            '₦${formatThousand(ride.fare.totalBeforeDiscount)}',
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Fare',
                            style: TextStyles.body1.copyWith(
                              fontSize: FontSizes.s16,
                              color: AppColors.onAccent,
                            ),
                          ),
                          Text(
                            '₦${formatThousand(ride.fare.totalFare)}',
                            style: TextStyles.t1.copyWith(
                              fontSize: FontSizes.s18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      Gap(10.0),

                      Text(
                        'Kindly make payment before ${formatDateTime(ride.paymentDeadline ?? DateTime.now())} to avoid cancellation.',
                        style: TextStyles.t2.copyWith(
                          fontSize: FontSizes.s14,
                          color: AppColors.orange400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Gap(10),

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

            // Gap(16.0),
            TextButton(
              onPressed: () {
                _showPayLaterDialog(context, ref);
              },
              child: Text(
                'Pay later',
                style: TextStyles.btnStyle.copyWith(
                  fontSize: 16.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            Gap(30.0),
          ],
        ),
      ),
    );
  }

  void _showPayLaterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pay Later',
          style: TextStyles.t3.copyWith(
            fontSize: FontSizes.s20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to pay later? Your ride will be cancelled if payment is not made before the deadline.',
          style: TextStyles.h3.copyWith(
            fontSize: FontSizes.s14,
            color: AppColors.surface500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s16,
                color: AppColors.surface500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(rideNotifierProvider.notifier).clearRoute();
              Navigator.pop(context);
            },
            child: Text(
              'Confirm',
              style: TextStyles.t1.copyWith(
                fontSize: FontSizes.s16,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
