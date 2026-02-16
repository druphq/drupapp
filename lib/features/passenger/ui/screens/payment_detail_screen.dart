import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  const PaymentDetailScreen({super.key, required this.paymentInfo});
  final PaymentHistoryItem paymentInfo;

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final pickUpAddress = widget.paymentInfo.entityId?.pickup?.name ?? '';
    final dropOffAddress = widget.paymentInfo.entityId?.dropoff?.name ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Payment Details',
          style: TextStyles.t1.copyWith(fontSize: FontSizes.s18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.onAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Detail',
                textAlign: TextAlign.center,
                style: TextStyles.t1.copyWith(
                  fontSize: FontSizes.s18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onAccent,
                ),
              ),
              Gap(16.0),
              // Pickup & Dropoff
              if (pickUpAddress.isNotEmptyOrNull ||
                  dropOffAddress.isNotEmptyOrNull) ...[
                _buildLocationRow(
                  Icons.circle,
                  pickUpAddress,
                  AppColors.pickupMarker,
                ),
                Container(
                  margin: const EdgeInsets.only(left: 11),
                  height: 20,
                  width: 2,
                  color: AppColors.divider,
                ),
                _buildLocationRow(
                  Icons.location_on,
                  dropOffAddress,
                  AppColors.destinationMarker,
                ),
                const Gap(12),
              ],
            ],
          ),

          Gap(20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment',
                textAlign: TextAlign.center,
                style: TextStyles.t1.copyWith(
                  fontSize: FontSizes.s18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onAccent,
                ),
              ),
              Gap(16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount Paid',
                    style: TextStyles.h2.copyWith(
                      fontSize: FontSizes.s16,
                      color: AppColors.onAccent,
                    ),
                  ),
                  Text(
                    '₦${formatThousand(widget.paymentInfo.amount)}',
                    style: TextStyles.t1.copyWith(
                      fontSize: FontSizes.s20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date',
                    style: TextStyles.h2.copyWith(
                      fontSize: FontSizes.s16,
                      color: AppColors.onAccent,
                    ),
                  ),
                  Text(
                    formatDateTime(widget.paymentInfo.createdAt),
                    style: TextStyles.t1.copyWith(
                      fontSize: FontSizes.s16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status',
                    style: TextStyles.h2.copyWith(
                      fontSize: FontSizes.s16,
                      color: AppColors.onAccent,
                    ),
                  ),
                  Text(
                    widget.paymentInfo.status,
                    style: TextStyles.t1.copyWith(
                      fontSize: FontSizes.s16,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.paymentInfo.status.toLowerCase() == 'success'
                          ? Colors.green
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
              Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reference',
                    style: TextStyles.h2.copyWith(
                      fontSize: FontSizes.s16,
                      color: AppColors.onAccent,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      widget.paymentInfo.reference,
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Gap(32),
          CustomButton(text: 'View Receipt', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String address, Color color) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const Gap(12),
        Expanded(
          child: Text(
            address,
            style: TextStyles.t2.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
