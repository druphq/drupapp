import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import 'package:drup/features/passenger/ui/widgets/driver_info_card.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/convert_util.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../di/providers.dart';

class RideDetailsScreen extends ConsumerStatefulWidget {
  const RideDetailsScreen({super.key, required this.ride});
  final BookedRide ride;

  @override
  ConsumerState<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends ConsumerState<RideDetailsScreen> {
  BookedRide? _ride;
  bool _isLoading = true;
  String? _error;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _fetchRide();
  }

  Future<void> _fetchRide() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final repo = ref.read(rideRepositoryProvider);
    final response = await repo.getRideById(widget.ride.id);
    if (response.success && response.data != null) {
      setState(() {
        _ride = response.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.message ?? 'Failed to load ride details';
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Status helpers
  // ---------------------------------------------------------------------------

  bool get _isPending =>
      _ride != null && _ride!.paymentStatus.toLowerCase() == 'pending';

  bool get _isExpired =>
      _ride != null && _ride!.status.toLowerCase() == 'expired';

  bool get _canCancel {
    if (_ride == null) return false;
    final s = _ride!.status.toLowerCase();
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

    if (_error != null || _ride == null) {
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
                  onPressed: _fetchRide,
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

    final ride = _ride!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomActions(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildHeaderCard(ride),
          const Gap(12),
          _buildMapPreview(ride),
          const Gap(12),
          _buildRouteCard(ride),
          const Gap(12),
          _buildDriverCard(ride),
          const Gap(12),
          if (ride.isScheduled) ...[_buildScheduleCard(ride), const Gap(12)],
          _buildFareCard(ride),
          const Gap(12),
          _buildHelpCard(),
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
        'Ride Details',
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
  // Header card – status badge, ride type, ref, date
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard(BookedRide ride) {
    final dateStr = DateFormat(
      'dd MMM yyyy  •  hh:mm a',
    ).format(ride.createdAt);

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
                  color: statusBg(ride.status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ride.status.replaceAll('_', ' ').capitalizeFirstChar(),
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor(ride.status),
                  ),
                ),
              ),
              const Spacer(),
              // Vehicle type
              Icon(Icons.drive_eta, size: 20, color: AppColors.textSecondary),
              const Gap(4),
              Text(
                ride.vehicleType.capitalizeFirstChar(),
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
              Clipboard.setData(ClipboardData(text: ride.rideNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: Row(
              children: [
                Text(
                  'Ref: ${ride.rideNumber}',
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

          // Ride type badge
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
                Icon(Icons.directions_car, size: 18, color: AppColors.accent),
                const Gap(6),
                Text(
                  'Ride Type: ${ride.rideType.capitalizeFirstChar()}',
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map preview
  // ---------------------------------------------------------------------------

  Widget _buildMapPreview(BookedRide ride) {
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
                  ride.pickup.coordinates.latitude,
                  ride.pickup.coordinates.longitude,
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
                      '${formatDistance(ride.estimatedDistance.toDouble())}, ${formatDuration(ride.estimatedDuration)}',
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

  Widget _buildRouteCard(BookedRide ride) {
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
                    ride.pickup.name.isNotEmpty
                        ? ride.pickup.name
                        : ride.pickup.address,
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
                    ride.dropoff.name.isNotEmpty
                        ? ride.dropoff.name
                        : ride.dropoff.address,
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
  // Driver card
  // ---------------------------------------------------------------------------

  Widget _buildDriverCard(BookedRide ride) {
    if (ride.driver != null) {
      return _card(
        title: 'Driver',
        child: DriverInfoCard(bookedRide: ride),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              'Driver\'s detail will appear once a driver is assigned to your ride.',
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Schedule card – only for scheduled rides
  // ---------------------------------------------------------------------------

  Widget _buildScheduleCard(BookedRide ride) {
    return _card(
      title: 'Schedule',
      child: Column(
        children: [
          _infoRow(
            Icons.calendar_today_outlined,
            'Date',
            DateFormat(
              'dd MMM yyyy',
            ).format(ride.scheduledTime ?? ride.createdAt),
          ),
          const Gap(10),
          _infoRow(
            Icons.access_time_outlined,
            'Time',
            DateFormat('hh:mm a').format(ride.scheduledTime ?? ride.createdAt),
          ),
          if (ride.pickupWindow != null) ...[
            const Gap(10),
            _infoRow(
              Icons.timelapse_outlined,
              'Window',
              '${DateFormat('hh:mm a').format(ride.pickupWindow!.start)} – ${DateFormat('hh:mm a').format(ride.pickupWindow!.end)}',
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fare card
  // ---------------------------------------------------------------------------

  Widget _buildFareCard(BookedRide ride) {
    final fare = ride.fare;
    return _card(
      title: 'Fare Breakdown',
      child: Column(
        children: [
          _fareRow('Base fare', fare.baseFare),
          _fareRow('Distance fare', fare.distanceFare),
          _fareRow('Time fare', fare.timeFare),
          if (fare.surgePricing > 0)
            _fareRow('Surge pricing', fare.surgePricing),
          _fareRow('Service fee', fare.serviceFee),
          if (fare.tax > 0) _fareRow('Tax', fare.tax),
          if (fare.tip > 0) _fareRow('Tip', fare.tip),
          if (fare.waitingFare != null && fare.waitingFare! > 0)
            _fareRow('Waiting fare', fare.waitingFare!),
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
            children: [
              Icon(
                _isExpired
                    ? Icons.error_outline
                    : _isPending
                    ? Icons.schedule
                    : Icons.check_circle_outline,
                size: 16,
                color: _isExpired
                    ? AppColors.red400
                    : _isPending
                    ? AppColors.orange400
                    : AppColors.green400,
              ),
              const Gap(4),
              Text(
                _isExpired
                    ? 'Payment Expired'
                    : 'Payment: ${ride.paymentStatus.capitalizeFirstChar()}',
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: _isExpired
                      ? AppColors.red400
                      : _isPending
                      ? AppColors.orange400
                      : AppColors.green400,
                ),
              ),
              const Spacer(),
              Text(
                ride.paymentMethod.capitalizeFirstChar(),
                style: TextStyles.t2.copyWith(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (_isPending && ride.paymentDeadline != null) ...[
            const Gap(8),
            Text(
              'Kindly make payment before ${formatDateTime(ride.paymentDeadline!)} to avoid cancellation.',
              style: TextStyles.t2.copyWith(
                fontSize: 13,
                color: AppColors.orange400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Help card
  // ---------------------------------------------------------------------------

  Widget _buildHelpCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Corners.c20),
        child: InkWell(
          borderRadius: BorderRadius.circular(Corners.c20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                const Gap(12),
                Text(
                  'Get help with ride',
                  style: TextStyles.t2.copyWith(
                    fontSize: FontSizes.s14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom action bar
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
                        'This ride has expired. Payment is no longer available.',
                        style: TextStyles.t2.copyWith(
                          fontSize: 13,
                          color: AppColors.red400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_isExpired && _isPending)
              CustomButton(text: 'Make Payment', onPressed: _handlePayment),
            if (!_isExpired && _isPending && _canCancel) const Gap(10),
            if (_canCancel)
              CustomButton(
                text: 'Cancel Ride',
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
        .initializePayment(rideId: _ride!.id, paymentMethod: 'card');

    if (result?.authorizationUrl != null && mounted) {
      context.push(
        AppRoutes.paymentWebViewRoute,
        extra: {
          'authorizationUrl': result!.authorizationUrl!,
          'onPaymentComplete': () async {
            await _fetchRide();
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
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
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
        .cancelRide(_ride!.id, reason: 'User cancelled ride');

    setState(() => _isCancelling = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel ride. Please try again.'),
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
