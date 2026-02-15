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
      appBar: AppBar(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.textLight),
            const Gap(16),
            Text(
              _errorMessage!,
              style: TextStyles.t2.copyWith(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            TextButton(
              onPressed: _fetchPaymentHistory,
              child: Text(
                'Retry',
                style: TextStyles.t2.copyWith(
                  fontSize: 14,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
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
    return RefreshIndicator(
      onRefresh: _fetchPaymentHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          final payment = _payments[index];
          return _buildPaymentCard(payment);
        },
        separatorBuilder: (context, index) => _buildDivider(),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentHistoryItem payment) {
    final formattedDate = formatDateTime(payment.createdAt);
    final formattedAmount = '₦${formatThousand(payment.amount)}';
    final statusColor = _getStatusColor(payment.status);
    final statusLabel = _capitalizeFirst(payment.status);

    // Location info from entity
    final pickupName = payment.entityId?.pickup?.name ?? '';
    final dropoffName = payment.entityId?.dropoff?.name ?? '';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.transparent,
      elevation: 0.0,
      child: InkWell(
        onTap: () {
          context.push(AppRoutes.paymentDetailRoute, extra: payment);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyles.t2.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
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

              // Pickup & Dropoff
              if (pickupName.isNotEmpty || dropoffName.isNotEmpty) ...[
                _buildLocationRow(
                  Icons.circle,
                  pickupName.isNotEmpty ? pickupName : 'Pickup',
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
                  dropoffName.isNotEmpty ? dropoffName : 'Dropoff',
                  AppColors.destinationMarker,
                ),
                const Gap(12),
              ],

              // Status & Payment method
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyles.t2.copyWith(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _capitalizeFirst(payment.paymentMethod),
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

  Widget _buildLocationRow(IconData icon, String address, Color color) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const Gap(12),
        Expanded(
          child: Text(
            address,
            style: TextStyles.t2.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider);
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
}
