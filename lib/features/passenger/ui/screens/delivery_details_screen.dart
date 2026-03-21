import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/di/providers.dart';
import 'package:drup/features/passenger/model/delivery_api_models.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/convert_util.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  const DeliveryDetailsScreen({super.key, required this.deliveryId});
  final String deliveryId;

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends ConsumerState<DeliveryDetailsScreen> {
  BookedDelivery? _delivery;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _fetchDelivery();
  }

  Future<void> _fetchDelivery() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(deliveryRepositoryProvider);
    final response = await repo.getDeliveryById(widget.deliveryId);

    if (response.success && response.data != null) {
      setState(() {
        _delivery = response.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.message ?? 'Failed to load delivery details';
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  bool get _isPending =>
      _delivery != null && _delivery!.paymentStatus.toLowerCase() == 'pending';

  bool get _isExpired =>
      _delivery != null && _delivery!.status.toLowerCase() == 'expired';

  bool get _canCancel {
    if (_delivery == null) return false;
    final s = _delivery!.status.toLowerCase();
    return s == 'booked' || s == 'pending';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _delivery == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.textLight),
                const Gap(16),
                Text(
                  _error ?? 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: TextStyles.t2.copyWith(color: AppColors.textSecondary),
                ),
                const Gap(12),
                TextButton(
                  onPressed: _fetchDelivery,
                  child: Text(
                    'Retry',
                    style: TextStyles.btnStyle.copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final delivery = _delivery!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomActions(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildHeaderCard(delivery),
          const Gap(12),
          _buildMapPreview(delivery),
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        'Delivery Details',
        style: TextStyles.t1.copyWith(
          fontSize: FontSizes.s18,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.onAccent),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header card – status badge, ride number, date
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(BookedDelivery delivery) {
    final dateStr = DateFormat(
      'dd MMM yyyy  •  hh:mm a',
    ).format(delivery.createdAt);

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
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg(delivery.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  delivery.status.replaceAll('_', ' ').capitalizeFirstChar(),
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor(delivery.status),
                  ),
                ),
              ),
              const Spacer(),
              // Vehicle type
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

          // Reference
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
          const Gap(4),
          Text(
            dateStr,
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          // Delivery code
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
                    'Delivery Code: ${delivery.deliveryCode}',
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
  // Map preview
  // ---------------------------------------------------------------------------

  Widget _buildMapPreview(BookedDelivery delivery) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Corners.c20),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  delivery.pickup.coordinates.latitude,
                  delivery.pickup.coordinates.longitude,
                ),
                zoom: 13,
              ),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              liteModeEnabled: true,
            ),
            // Distance / duration badge
            Positioned(
              left: 12,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Corners.c20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_split, size: 18, color: AppColors.accent),
                    const Gap(4),
                    Text(
                      '${formatDistance(delivery.estimatedDistance.toDouble())}, ${formatDuration(delivery.estimatedDuration)}',
                      style: TextStyles.t2.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
  // Route card – pickup & dropoff
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard(BookedDelivery delivery) {
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
                  // Pickup
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
                  // Dropoff
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
          if (r.notes != null && r.notes!.isNotEmpty) ...[
            const Gap(10),
            _infoRow(Icons.note_outlined, 'Notes', r.notes!),
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
          // if (p.size != null && p.size!.isNotEmpty) ...[
          //   const Gap(10),
          //   _infoRow(
          //     Icons.straighten_outlined,
          //     'Size',
          //     p.size!.capitalizeFirstChar(),
          //   ),
          // ],
          // if (p.weight != null) ...[
          //   const Gap(10),
          //   _infoRow(
          //     Icons.fitness_center_outlined,
          //     'Weight',
          //     '${p.weight!.toStringAsFixed(1)} kg',
          //   ),
          // ],
          // if (p.quantity != null) ...[
          //   const Gap(10),
          //   _infoRow(Icons.numbers_outlined, 'Quantity', '${p.quantity}'),
          // ],
          // if (p.fragile) ...[
          //   const Gap(10),
          //   _infoRow(Icons.warning_amber_rounded, 'Fragile', 'Yes'),
          // ],
          // if (delivery.userNotes != null && delivery.userNotes!.isNotEmpty) ...[
          //   const Gap(10),
          //   _infoRow(Icons.comment_outlined, 'Comment', delivery.userNotes!),
          // ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Status:',
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _isExpired
                    ? 'Expired'
                    : delivery.paymentStatus.capitalizeFirstChar(),
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: _isExpired
                      ? AppColors.red400
                      : _isPending
                      ? AppColors.orange400
                      : AppColors.green400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom action bar: Cancel / Make Payment
  // ---------------------------------------------------------------------------

  Widget? _buildBottomActions() {
    if (!_isPending && !_canCancel && !_isExpired) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExpired)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(Corners.c8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: AppColors.red400,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'This delivery has expired. Payment is no longer available.',
                        style: TextStyles.t2.copyWith(
                          fontSize: 13,
                          color: AppColors.red400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // TODO: Remove – temporary dev-only cancel for expired deliveries
            if (_isExpired && kDebugMode) ...[
              const Gap(10),
              CustomButton(
                text: 'Cancel Expired Delivery (DEV)',
                isLoading: _isCancelling,
                backgroundColor: AppColors.red50,
                textStyle: TextStyles.t2.copyWith(
                  fontSize: FontSizes.s16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red400,
                ),
                onPressed: _handleCancel,
              ),
            ],
            if (!_isExpired && _isPending)
              CustomButton(text: 'Make Payment', onPressed: _handlePayment),
            if (!_isExpired && _isPending && _canCancel) const Gap(10),
            if (_canCancel)
              CustomButton(
                text: 'Cancel Delivery',
                isLoading: _isCancelling,
                backgroundColor: AppColors.red50,
                textStyle: TextStyles.t2.copyWith(
                  fontSize: FontSizes.s16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red400,
                ),
                onPressed: _handleCancel,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _handlePayment() async {
    final result = await ref
        .read(rideNotifierProvider.notifier)
        .initializePayment(rideId: _delivery!.id, paymentMethod: 'card');

    if (result?.authorizationUrl != null && mounted) {
      context.push(
        AppRoutes.paymentWebViewRoute,
        extra: {
          'authorizationUrl': result!.authorizationUrl!,
          'onPaymentComplete': () async {
            // In a real implementation, refresh delivery details here
          },
        },
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize payment. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Delivery'),
        content: const Text('Are you sure you want to cancel this delivery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.red400),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    final success = await ref
        .read(rideNotifierProvider.notifier)
        .cancelRide(_delivery!.id, reason: 'User cancelled delivery');

    setState(() => _isCancelling = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery cancelled successfully.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel delivery. Please try again.'),
          ),
        );
      }
    }
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
}
