import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/model/delivery_api_models.dart';
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

class DeliveryDetailBottomsheet extends ConsumerWidget {
  const DeliveryDetailBottomsheet({super.key, required this.bookedDelivery});
  final BookedDelivery? bookedDelivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookedDelivery == null) {
      return const SizedBox.shrink();
    }

    final delivery = bookedDelivery!;
    final rideState = ref.watch(rideNotifierProvider);

    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Corners.c20),
            topRight: Radius.circular(Corners.c20),
          ),
        ),
        child: Column(
          children: [
            // ── Header bar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Corners.c20),
                  topRight: Radius.circular(Corners.c20),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Gap(50),
                  Text(
                    'Delivery Booked',
                    textAlign: TextAlign.center,
                    style: TextStyles.t1.copyWith(
                      fontSize: FontSizes.s24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onAccent,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pending Payment',
                      style: TextStyles.t2.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  _buildHeaderCard(context, delivery),
                  const Gap(12),
                  _buildRouteCard(delivery),
                  const Gap(12),
                  _buildRecipientCard(delivery),
                  const Gap(12),
                  _buildPackageCard(delivery),
                  const Gap(12),
                  _buildFareCard(delivery),
                  const Gap(24),
                ],
              ),
            ),

            // ── Bottom actions ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 8,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomButton(
                      text: 'Make Payment',
                      isLoading: rideState.isLoading,
                      onPressed: () async {
                        final result = await ref
                            .read(rideNotifierProvider.notifier)
                            .initializePayment(
                              rideId: delivery.id,
                              paymentMethod: 'card',
                            );

                        if (!context.mounted) return;

                        if (result?.authorizationUrl != null) {
                          context.push(
                            AppRoutes.paymentWebViewRoute,
                            extra: {
                              'authorizationUrl': result!.authorizationUrl!,
                              'onPaymentComplete': () async {
                                context.pop();
                                context.pop();

                                await context.push(
                                  AppRoutes.deliveryDetailsRoute,
                                  extra: delivery.id,
                                );
                                ref
                                    .read(rideNotifierProvider.notifier)
                                    .clearRoute();
                              },
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to initialize payment. Please try again.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () => _showPayLaterDialog(context, ref),
                      child: Text(
                        'Pay later',
                        style: TextStyles.btnStyle.copyWith(
                          fontSize: 16.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header card – delivery code, ref, vehicle
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(BuildContext context, BookedDelivery delivery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(Corners.c8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const Gap(6),
                    Text(
                      'Delivery',
                      style: TextStyles.t2.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.two_wheeler, size: 20, color: AppColors.textSecondary),
              const Gap(4),
              Text(
                delivery.vehicleType.capitalizeFirstChar(),
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Gap(12),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: delivery.rideNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: Row(
              children: [
                Text(
                  'Ref: ${delivery.rideNumber}',
                  style: TextStyles.t2.copyWith(
                    fontSize: FontSizes.s14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
          if (delivery.deliveryCode.isNotEmpty) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(Corners.c8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, size: 18, color: AppColors.accent),
                  const Gap(6),
                  Text(
                    'Code: ${delivery.deliveryCode}',
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Route card – pickup & dropoff
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard(BookedDelivery delivery) {
    return _card(
      title: 'Route',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  height: 18,
                  width: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.pickupMarker,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.circle, color: Colors.white, size: 8),
                ),
                Expanded(child: Container(width: 2, color: AppColors.divider)),
                const Icon(
                  Icons.location_on,
                  size: 22,
                  color: AppColors.red400,
                ),
              ],
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup',
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    delivery.pickup.name.isNotEmpty
                        ? delivery.pickup.name
                        : delivery.pickup.address,
                    style: TextStyles.t2.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(16),
                  Text(
                    'Dropoff',
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    delivery.dropoff.name.isNotEmpty
                        ? delivery.dropoff.name
                        : delivery.dropoff.address,
                    style: TextStyles.t2.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recipient card
  // ---------------------------------------------------------------------------

  Widget _buildRecipientCard(BookedDelivery delivery) {
    final r = delivery.recipient;
    return _card(
      title: 'Recipient',
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Name', r.name),
          const Gap(10),
          _infoRow(Icons.phone_outlined, 'Phone', r.phone),
          if (r.alternatePhone != null && r.alternatePhone!.isNotEmpty) ...[
            const Gap(10),
            _infoRow(
              Icons.phone_forwarded_outlined,
              'Alt. Phone',
              r.alternatePhone!,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Package card
  // ---------------------------------------------------------------------------

  Widget _buildPackageCard(BookedDelivery delivery) {
    final p = delivery.package;
    return _card(
      title: 'Package',
      child: Column(
        children: [
          _infoRow(Icons.inventory_2_outlined, 'Description', p.description),
          if (p.size != null && p.size!.isNotEmpty) ...[
            const Gap(10),
            _infoRow(
              Icons.straighten_outlined,
              'Size',
              p.size!.capitalizeFirstChar(),
            ),
          ],
          if (p.weight != null) ...[
            const Gap(10),
            _infoRow(
              Icons.fitness_center_outlined,
              'Weight',
              '${p.weight!.toStringAsFixed(1)} kg',
            ),
          ],
          if (p.fragile) ...[
            const Gap(10),
            _infoRow(Icons.warning_amber_rounded, 'Fragile', 'Yes'),
          ],
          if (delivery.userNotes != null && delivery.userNotes!.isNotEmpty) ...[
            const Gap(10),
            _infoRow(Icons.comment_outlined, 'Comment', delivery.userNotes!),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fare card
  // ---------------------------------------------------------------------------

  Widget _buildFareCard(BookedDelivery delivery) {
    final fare = delivery.fare;
    return _card(
      title: 'Fare Breakdown',
      child: Column(
        children: [
          _fareRow('Base fare', fare.baseFare),
          _fareRow('Distance fare', fare.distanceFare),
          _fareRow('Time fare', fare.timeFare),
          if (fare.packageSurcharge > 0)
            _fareRow('Package surcharge', fare.packageSurcharge),
          if (fare.surgePricing > 0)
            _fareRow('Surge pricing', fare.surgePricing),
          _fareRow('Service fee', fare.serviceFee),
          if (fare.tax > 0) _fareRow('Tax', fare.tax),
          if (fare.discount > 0)
            _fareRow('Discount', -fare.discount, isDiscount: true),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyles.t1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₦${formatThousand(fare.totalFare)}',
                style: TextStyles.t1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.orange400),
              const Gap(4),
              Text(
                'Payment: Pending',
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.orange400,
                ),
              ),
              const Spacer(),
              Text(
                delivery.paymentMethod.capitalizeFirstChar(),
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable widgets
  // ---------------------------------------------------------------------------

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyles.t1.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const Gap(10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyles.t2.copyWith(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _fareRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.t2.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${isDiscount ? "- " : ""}₦${formatThousand(amount.abs())}',
            style: TextStyles.t2.copyWith(
              fontSize: 14,
              color: isDiscount ? AppColors.green400 : AppColors.onAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pay later dialog
  // ---------------------------------------------------------------------------

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
          'Are you sure you want to pay later? Your delivery will be cancelled if payment is not made before the deadline.',
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
