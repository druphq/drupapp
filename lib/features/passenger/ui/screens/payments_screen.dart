import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../model/ride_api_models.dart';
import '../../../../di/providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  bool _isLoading = true;
  List<PaymentHistoryItem> _payments = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPaymentHistory();
    });
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rideRepo = ref.read(rideRepositoryProvider);
    final response = await rideRepo.getPaymentHistory();

    if (response.success && response.data != null) {
      setState(() {
        _payments = response.data!.payments;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message ?? 'Failed to load payments';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Payments',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Padding(
              padding: EdgeInsets.only(top: height * 0.2),
              child: const Align(
                alignment: Alignment.topCenter,
                child: SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          : _errorMessage != null
          ? _buildErrorState(height)
          : _payments.isEmpty
          ? _buildEmptyState(height)
          : _buildPaymentList(),
    );
  }

  Widget _buildErrorState(double height) {
    return Padding(
      padding: EdgeInsets.only(top: height * 0.2),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 80, color: AppColors.textLight),
              const Gap(16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyles.t2.copyWith(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: _fetchPaymentHistory,
                child: Text(
                  'Retry',
                  style: TextStyles.btnStyle.copyWith(
                    fontSize: 16,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double height) {
    return Padding(
      padding: EdgeInsets.only(top: height * 0.2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.payment, size: 80, color: AppColors.textLight),
            const Gap(16),
            Text(
              'No payments yet',
              style: TextStyles.t2.copyWith(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(8),
            Text(
              'Your payment history will appear here',
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList() {
    // Group payments by month/year
    Map<String, List<PaymentHistoryItem>> grouped = {};
    for (final payment in _payments) {
      final key = formatMonthYear(payment.createdAt);
      grouped.putIfAbsent(key, () => []).add(payment);
    }

    // Flatten to a list of headers and payments
    final List<dynamic> items = [];
    grouped.forEach((month, payments) {
      items.add(month);
      items.addAll(payments);
    });

    return RefreshIndicator(
      onRefresh: _fetchPaymentHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is String) {
            // Section header
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                item,
                style: TextStyles.t1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          } else if (item is PaymentHistoryItem) {
            return _buildPaymentCard(item);
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildPaymentCard(PaymentHistoryItem payment) {
    final formattedDate = formatTimeDate(payment.createdAt);
    final formattedAmount = '₦${formatThousand(payment.amount)}';
    final statusColor = _statusColor(payment.status);
    final statusBgColor = _statusBg(payment.status);
    final statusLabel = _capitalizeFirst(payment.status);

    final pickupName = payment.entityId?.pickup?.name ?? '';
    final dropoffName = payment.entityId?.dropoff?.name ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.lg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.lg),
        onTap: () {
          context.push(AppRoutes.paymentDetailRoute, extra: payment);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reference & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      payment.reference,
                      style: TextStyles.t2.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    formattedAmount,
                    style: TextStyles.t1.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // Pickup & Dropoff (dot-line)
              if (pickupName.isNotEmpty || dropoffName.isNotEmpty) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            height: 14,
                            width: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.pickupMarker,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 6,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.divider,
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.red400,
                          ),
                        ],
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickupName.isNotEmpty ? pickupName : 'Pickup',
                              style: TextStyles.t2.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(12),
                            Text(
                              dropoffName.isNotEmpty ? dropoffName : 'Dropoff',
                              style: TextStyles.t2.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
              ],

              // Status badge & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyles.t2.copyWith(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return AppColors.green400;
      case 'pending':
        return AppColors.orange400;
      case 'failed' || 'cancelled':
        return AppColors.red400;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'success' || 'completed':
        return AppColors.green50;
      case 'pending':
        return AppColors.orange50;
      case 'failed' || 'cancelled':
        return AppColors.red50;
      default:
        return AppColors.grey50;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
