import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  const PaymentDetailScreen({super.key, required this.paymentInfo});
  final PaymentHistoryItem paymentInfo;

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return AppColors.green400;
      case 'failed' || 'cancelled':
        return AppColors.red400;
      case 'pending':
        return AppColors.orange400;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return AppColors.green50;
      case 'failed' || 'cancelled':
        return AppColors.red50;
      case 'pending':
        return AppColors.orange50;
      default:
        return AppColors.grey50;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final payment = widget.paymentInfo;
    final pickUpAddress = payment.entityId?.pickup?.name ?? '';
    final dropOffAddress = payment.entityId?.dropoff?.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Payment Details',
          style: TextStyles.t1.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ────────────────────────────────────────────────
          _buildHeaderCard(payment),
          const Gap(12),

          // ── Route card ─────────────────────────────────────────────────
          if (pickUpAddress.isNotEmptyOrNull ||
              dropOffAddress.isNotEmptyOrNull) ...[
            _buildRouteCard(pickUpAddress, dropOffAddress),
            const Gap(12),
          ],

          // ── Payment info card ──────────────────────────────────────────
          _buildPaymentInfoCard(payment),
          const Gap(12),

          // ── Reference card ─────────────────────────────────────────────
          _buildReferenceCard(payment),
          const Gap(24),

          // ── View Receipt button ────────────────────────────────────────
          CustomButton(
            text: 'View Receipt',
            onPressed: () {
              context.push(AppRoutes.paymentReceiptRoute, extra: payment);
            },
            backgroundColor: AppColors.accent,
            textStyle: TextStyles.btnStyle.copyWith(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header card – amount + status badge
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(PaymentHistoryItem payment) {
    final statusLabel = payment.status.capitalizeFirstChar();
    final statusClr = _statusColor(payment.status);
    final statusBgClr = _statusBg(payment.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        children: [
          // Amount
          Text(
            '₦${formatThousand(payment.amount)}',
            style: TextStyles.t1.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: statusBgClr,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyles.t2.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusClr,
              ),
            ),
          ),
          const Gap(8),
          // Date
          Text(
            formatDateTime(payment.createdAt),
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Route card – pickup & dropoff with dot-line
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard(String pickup, String dropoff) {
    return _card(
      title: 'Route',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dots + line
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
                    pickup.isNotEmpty ? pickup : 'Pickup',
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
                    dropoff.isNotEmpty ? dropoff : 'Dropoff',
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
  // Payment info card – date, status
  // ---------------------------------------------------------------------------

  Widget _buildPaymentInfoCard(PaymentHistoryItem payment) {
    return _card(
      title: 'Payment Info',
      child: Column(
        children: [
          _infoRow(
            Icons.calendar_today_outlined,
            'Date',
            formatDateTime(payment.createdAt),
          ),
          const Gap(10),
          _infoRow(
            Icons.payments_outlined,
            'Amount',
            '₦${formatThousand(payment.amount)}',
          ),
          const Gap(10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const Gap(10),
              SizedBox(
                width: 80,
                child: Text(
                  'Status',
                  style: TextStyles.t2.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(payment.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.status.capitalizeFirstChar(),
                  style: TextStyles.t2.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(payment.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reference card – tap to copy
  // ---------------------------------------------------------------------------

  Widget _buildReferenceCard(PaymentHistoryItem payment) {
    return _card(
      title: 'Reference',
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: payment.reference));
          _showSnackbar('Reference copied to clipboard');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Corners.c8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  payment.reference,
                  style: TextStyles.t2.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(8),
              Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable helpers
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
