import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Shows full details of a nearby ride request and lets the driver
/// Accept or Decline it.
class RideRequestDetailScreen extends ConsumerStatefulWidget {
  const RideRequestDetailScreen({super.key, required this.ride});
  final Map<String, dynamic> ride;

  @override
  ConsumerState<RideRequestDetailScreen> createState() =>
      _RideRequestDetailScreenState();
}

class _RideRequestDetailScreenState
    extends ConsumerState<RideRequestDetailScreen> {
  bool _isActioning = false;

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> get _ride => widget.ride;

  String get _rideId => (_ride['_id'] ?? _ride['id'] ?? '').toString();

  bool get _isDelivery =>
      (_ride['rideType'] ?? _ride['ride_type'] ?? '')
          .toString()
          .toLowerCase() ==
      'delivery';

  String get _rideType =>
      (_ride['rideType'] ?? _ride['ride_type'] ?? '').toString();

  String get _vehicleType =>
      (_ride['vehicleType'] ?? _ride['vehicle_type'] ?? '').toString();

  String get _rideNumber =>
      (_ride['rideNumber'] ?? _ride['ride_number'] ?? '').toString();

  Map<String, dynamic> get _pickup => _ride['pickup'] is Map
      ? _ride['pickup'] as Map<String, dynamic>
      : <String, dynamic>{};

  Map<String, dynamic> get _dropoff => _ride['dropoff'] is Map
      ? _ride['dropoff'] as Map<String, dynamic>
      : <String, dynamic>{};

  Map<String, dynamic>? get _fare =>
      _ride['fare'] is Map ? _ride['fare'] as Map<String, dynamic> : null;

  Map<String, dynamic>? get _passengerInfo {
    if (_ride['passenger'] is Map)
      return _ride['passenger'] as Map<String, dynamic>;
    if (_ride['user'] is Map) return _ride['user'] as Map<String, dynamic>;
    return null;
  }

  double _num(dynamic v) => (v is num ? v.toDouble() : 0.0);

  DateTime get _createdAt =>
      DateTime.tryParse(
        (_ride['createdAt'] ?? _ride['created_at'] ?? '').toString(),
      ) ??
      DateTime.now();

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Ride Request',
          style: TextStyles.t1.copyWith(
            fontSize: FontSizes.s18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildHeaderCard(),
          const Gap(12),
          _buildMapPreview(),
          const Gap(12),
          _buildRouteCard(),
          const Gap(12),
          _buildPassengerCard(),
          const Gap(12),
          if (_fare != null) ...[_buildFareCard(), const Gap(12)],
          _buildDetailsCard(),
          const Gap(24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header card
  // ---------------------------------------------------------------------------

  Widget _buildHeaderCard() {
    final dateStr = DateFormat('dd MMM yyyy  •  hh:mm a').format(_createdAt);

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
              // Ride type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _rideType.capitalizeFirstChar(),
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                _isDelivery ? Icons.local_shipping_outlined : Icons.drive_eta,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const Gap(4),
              if (_vehicleType.isNotEmpty)
                Text(
                  _vehicleType.capitalizeFirstChar(),
                  style: TextStyles.t2.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (_rideNumber.isNotEmpty) ...[
            const Gap(12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _rideNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: Row(
                children: [
                  Text(
                    'Ref: $_rideNumber',
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
          ],
          const Gap(4),
          Text(
            dateStr,
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          // Fare highlight
          if (_fare != null) ...[
            const Gap(12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(Corners.c10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: AppColors.green400,
                  ),
                  const Gap(8),
                  Text(
                    'Estimated Earnings',
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      color: AppColors.green400,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₦${formatThousand(_num(_fare!['totalFare'] ?? _fare!['total_fare'] ?? 0))}',
                    style: TextStyles.t1.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green400,
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

  Widget _buildMapPreview() {
    final coords = _pickup['coordinates'] ?? _pickup['location'];
    double? lat;
    double? lng;
    if (coords is Map) {
      final c = coords as Map<String, dynamic>;
      lat = _num(c['latitude'] ?? c['lat']);
      lng = _num(c['longitude'] ?? c['lng'] ?? c['lon']);
    } else if (coords is List && coords.length >= 2) {
      lng = _num(coords[0]);
      lat = _num(coords[1]);
    }

    if (lat == null || lng == null || (lat == 0 && lng == 0)) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Corners.c20),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 13,
              ),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              liteModeEnabled: true,
            ),
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
                      '${formatDistance(_num(_ride['estimatedDistance'] ?? _ride['estimated_distance'] ?? 0))}, ${formatDuration((_ride['estimatedDuration'] ?? _ride['estimated_duration'] ?? 0) as int)}',
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
  // Route card
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard() {
    final pickupName = (_pickup['name'] ?? _pickup['address'] ?? 'Pickup')
        .toString();
    final dropoffName = (_dropoff['name'] ?? _dropoff['address'] ?? 'Dropoff')
        .toString();

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
                    pickupName,
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
                    dropoffName,
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
  // Passenger card
  // ---------------------------------------------------------------------------

  Widget _buildPassengerCard() {
    final p = _passengerInfo;
    if (p == null) {
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
                'Passenger details are available after acceptance.',
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

    final name =
        '${p['firstName'] ?? p['first_name'] ?? ''} ${p['lastName'] ?? p['last_name'] ?? ''}'
            .trim();
    final photo = (p['profilePhoto'] ?? p['avatar'] ?? '').toString();
    final rating = p['rating'];

    return _card(
      title: 'Passenger',
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surface,
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Passenger',
                  style: TextStyles.t2.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (rating != null) ...[
                  const Gap(2),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                      const Gap(3),
                      Text(
                        '$rating',
                        style: TextStyles.t2.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fare card
  // ---------------------------------------------------------------------------

  Widget _buildFareCard() {
    final f = _fare!;
    return _card(
      title: 'Fare Breakdown',
      child: Column(
        children: [
          _fareRow('Base fare', _num(f['baseFare'] ?? f['base_fare'])),
          _fareRow(
            'Distance fare',
            _num(f['distanceFare'] ?? f['distance_fare']),
          ),
          _fareRow('Time fare', _num(f['timeFare'] ?? f['time_fare'])),
          if (_num(f['surgePricing'] ?? f['surge_pricing']) > 0)
            _fareRow(
              'Surge pricing',
              _num(f['surgePricing'] ?? f['surge_pricing']),
            ),
          _fareRow('Service fee', _num(f['serviceFee'] ?? f['service_fee'])),
          if (_num(f['tax']) > 0) _fareRow('Tax', _num(f['tax'])),
          if (_num(f['discount']) > 0)
            _fareRow('Discount', -_num(f['discount']), isDiscount: true),
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
                '₦${formatThousand(_num(f['totalFare'] ?? f['total_fare'] ?? 0))}',
                style: TextStyles.t1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Additional details card
  // ---------------------------------------------------------------------------

  Widget _buildDetailsCard() {
    final paymentMethod =
        ((_ride['paymentMethod'] ?? _ride['payment_method'] ?? '').toString());
    final scheduledTime = _ride['scheduledTime'] ?? _ride['scheduled_time'];
    final notes = (_ride['notes'] ?? '').toString();

    return _card(
      title: 'Details',
      child: Column(
        children: [
          if (paymentMethod.isNotEmpty)
            _infoRow(
              Icons.payment,
              'Payment',
              paymentMethod.capitalizeFirstChar(),
            ),
          if (scheduledTime != null) ...[
            const Gap(10),
            _infoRow(
              Icons.schedule,
              'Scheduled',
              DateFormat('dd MMM yyyy, hh:mm a').format(
                DateTime.tryParse(scheduledTime.toString()) ?? DateTime.now(),
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const Gap(10),
            _infoRow(Icons.notes, 'Notes', notes),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom actions — Accept / Decline
  // ---------------------------------------------------------------------------

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
        child: Row(
          children: [
            // Decline
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isActioning ? null : _handleDecline,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Corners.c10),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red400,
                    ),
                  ),
                ),
              ),
            ),
            const Gap(12),
            // Accept
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isActioning ? null : _handleAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Corners.c10),
                    ),
                  ),
                  child: _isActioning
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Accept Ride',
                          style: TextStyles.t2.copyWith(
                            fontSize: FontSizes.s16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _handleAccept() async {
    setState(() => _isActioning = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    final success = await notifier.acceptRide(_rideId);

    if (mounted) {
      setState(() => _isActioning = false);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride accepted!')));
        Navigator.of(context).pop(true); // return true → refresh list
      } else {
        final err = ref.read(driverNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? 'Failed to accept ride. Try again.')),
        );
      }
    }
  }

  Future<void> _handleDecline() async {
    final reason = await _showDeclineDialog();
    if (reason == null) return;

    setState(() => _isActioning = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    final success = await notifier.declineRide(
      _rideId,
      reason: reason.isNotEmpty ? reason : null,
    );

    if (mounted) {
      setState(() => _isActioning = false);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride declined.')));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to decline. Try again.')),
        );
      }
    }
  }

  Future<String?> _showDeclineDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Provide a reason for declining (optional).',
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Corners.c10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('Decline', style: TextStyle(color: AppColors.red400)),
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
}
