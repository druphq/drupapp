import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
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
          Text(
            'Payment Summary',
            textAlign: TextAlign.center,
            style: TextStyles.t1.copyWith(
              fontSize: FontSizes.s24,
              fontWeight: FontWeight.w700,
              color: AppColors.onAccent,
            ),
          ),
          Gap(8),
          Text(
            'Below are the details of your payment.',
            textAlign: TextAlign.center,
            style: TextStyles.t2.copyWith(
              fontSize: FontSizes.s14,
              color: AppColors.textSecondary,
            ),
          ),
          Gap(32),
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
                  'Amount Paid',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onAccent,
                  ),
                ),
                Gap(4.0),
                Text(
                  '${formatThousand(widget.paymentInfo.amount)}',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Gap(16),
                Divider(color: AppColors.greyStrong),
                Gap(12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Method',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent,
                      ),
                    ),
                    Text(
                      widget.paymentInfo.paymentMethod,
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
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
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
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        widget.paymentInfo.reference ?? '-',
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
          ),
          Gap(32),
          CustomButton(
            text: 'View Receipt',
            onPressed: () {
              // TODO: Implement receipt viewing
            },
          ),
        ],
      ),
    );
  }
}
