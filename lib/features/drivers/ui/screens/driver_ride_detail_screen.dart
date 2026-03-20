import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/convert_util.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Driver-side ride detail screen.
///
/// Receives a [Map<String, dynamic>] ride object and displays its full info
/// plus driver-specific lifecycle actions (arrived, start, complete, cancel,
/// and per-passenger actions for shared rides).
class DriverRideDetailScreen extends ConsumerStatefulWidget {
  const DriverRideDetailScreen({super.key, required this.ride});
  final Map<String, dynamic> ride;

  @override
  ConsumerState<DriverRideDetailScreen> createState() =>
      _DriverRideDetailScreenState();
}

class _DriverRideDetailScreenState
    extends ConsumerState<DriverRideDetailScreen> {
  late Map<String, dynamic> _ride;
  bool _isActioning = false;
  List<Map<String, dynamic>> _passengers = [];
  bool _loadingPassengers = false;

  @override
  void initState() {
    super.initState();
    _ride = Map<String, dynamic>.from(widget.ride);
    _loadPassengersIfShared();
  }

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  String get _status => (_ride['status'] ?? '').toString().toLowerCase();

  String get _rideId => (_ride['_id'] ?? _ride['id'] ?? '').toString();

  bool get _isDelivery =>
      (_ride['rideType'] ?? _ride['ride_type'] ?? '')
          .toString()
          .toLowerCase() ==
      'delivery';

  bool get _isShared =>
      (_ride['rideType'] ?? _ride['ride_type'] ?? '')
          .toString()
          .toLowerCase() ==
      'shared';

  Map<String, dynamic> get _pickup => _ride['pickup'] is Map
      ? _ride['pickup'] as Map<String, dynamic>
      : <String, dynamic>{};

  Map<String, dynamic> get _dropoff => _ride['dropoff'] is Map
      ? _ride['dropoff'] as Map<String, dynamic>
      : <String, dynamic>{};

  Map<String, dynamic>? get _fare =>
      _ride['fare'] is Map ? _ride['fare'] as Map<String, dynamic> : null;

  double _num(dynamic v) => (v is num ? v.toDouble() : 0.0);

  DateTime get _createdAt =>
      DateTime.tryParse(
        (_ride['createdAt'] ?? _ride['created_at'] ?? '').toString(),
      ) ??
      DateTime.now();

  String get _vehicleType =>
      (_ride['vehicleType'] ?? _ride['vehicle_type'] ?? '').toString();

  String get _rideType =>
      (_ride['rideType'] ?? _ride['ride_type'] ?? '').toString();

  String get _rideNumber =>
      (_ride['rideNumber'] ?? _ride['ride_number'] ?? '').toString();

  Map<String, dynamic>? get _passengerInfo {
    if (_ride['passenger'] is Map) {
      return _ride['passenger'] as Map<String, dynamic>;
    }
    if (_ride['user'] is Map) {
      return _ride['user'] as Map<String, dynamic>;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle action checks
  // ---------------------------------------------------------------------------

  /// For shared rides, arrival is per-passenger (not ride-level).
  bool get _canArrive =>
      !_isShared &&
      (_status == 'matched' || _status == 'confirmed' || _status == 'accepted');

  /// For shared rides, start only when all passengers are picked up or no-show.
  bool get _canStart {
    if (_status != 'arrived') return false;
    if (_isShared) return _allPickedUp;
    return true;
  }

  /// For shared rides, complete only when all passengers are dropped off or no-show.
  bool get _canComplete {
    if (_status != 'in_progress' && _status != 'picked_up') return false;
    if (_isShared) return _allDroppedOff;
    return true;
  }

  bool get _canCancel =>
      _status != 'completed' && _status != 'cancelled' && _status != 'expired';

  // ---------------------------------------------------------------------------
  // Shared ride aggregate checks
  // ---------------------------------------------------------------------------

  bool get _allPickedUp {
    if (_passengers.isEmpty) return false;
    return _passengers.every((p) {
      final s = (p['status'] ?? '').toString().toLowerCase();
      return s == 'picked_up' || s == 'no_show';
    });
  }

  bool get _allDroppedOff {
    if (_passengers.isEmpty) return false;
    return _passengers.every((p) {
      final s = (p['status'] ?? '').toString().toLowerCase();
      return s == 'dropped_off' || s == 'no_show';
    });
  }

  // ---------------------------------------------------------------------------
  // Fetch passengers for shared rides
  // ---------------------------------------------------------------------------

  Future<void> _loadPassengersIfShared() async {
    if (!_isShared || _rideId.isEmpty) return;
    setState(() => _loadingPassengers = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    final result = await notifier.getPassengers(_rideId);
    if (mounted) {
      setState(() {
        _passengers = result;
        _loadingPassengers = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
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
          if (_isShared) ...[_buildSharedPassengersCard(), const Gap(12)],
          if (_fare != null) ...[_buildFareCard(), const Gap(12)],
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
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg(_status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _status.replaceAll('_', ' ').capitalizeFirstChar(),
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor(_status),
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
          const Gap(12),

          // Reference
          if (_rideNumber.isNotEmpty)
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
                  'Ride Type: ${_rideType.capitalizeFirstChar()}',
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
  // Passenger / rider card (shown to driver)
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
                'Passenger details will appear once assigned.',
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
    final phone = (p['phone'] ?? p['phoneNumber'] ?? '').toString();
    final photo = (p['profilePhoto'] ?? p['avatar'] ?? '').toString();

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
                if (phone.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    phone,
                    style: TextStyles.t2.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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
  // Shared ride passengers card
  // ---------------------------------------------------------------------------

  Widget _buildSharedPassengersCard() {
    return _card(
      title: 'Passengers',
      child: _loadingPassengers
          ? const Center(child: CircularProgressIndicator())
          : _passengers.isEmpty
          ? Text(
              'No passengers yet.',
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: _passengers.map((p) {
                final pId = (p['_id'] ?? p['id'] ?? p['passengerId'] ?? '')
                    .toString();
                final pStatus = (p['status'] ?? '').toString().toLowerCase();
                final name =
                    '${p['firstName'] ?? p['first_name'] ?? ''} ${p['lastName'] ?? p['last_name'] ?? ''}'
                        .trim();
                final pickup =
                    (p['pickup'] is Map
                        ? (p['pickup'] as Map)['address']
                        : '') ??
                    '';
                final dropoff =
                    (p['dropoff'] is Map
                        ? (p['dropoff'] as Map)['address']
                        : '') ??
                    '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Corners.c10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              name.isNotEmpty ? name : 'Passenger',
                              style: TextStyles.t2.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg(pStatus),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pStatus
                                  .replaceAll('_', ' ')
                                  .capitalizeFirstChar(),
                              style: TextStyles.t2.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor(pStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (pickup.toString().isNotEmpty) ...[
                        const Gap(6),
                        _miniLocation(
                          Icons.circle,
                          AppColors.pickupMarker,
                          pickup.toString(),
                        ),
                      ],
                      if (dropoff.toString().isNotEmpty) ...[
                        const Gap(4),
                        _miniLocation(
                          Icons.location_on,
                          AppColors.red400,
                          dropoff.toString(),
                        ),
                      ],
                      const Gap(8),
                      _buildPassengerActions(pId, pStatus),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _miniLocation(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const Gap(6),
        Expanded(
          child: Text(
            text,
            style: TextStyles.t2.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Per-passenger actions (shared rides)
  // ---------------------------------------------------------------------------

  Widget _buildPassengerActions(String passengerId, String pStatus) {
    final actions = <Widget>[];

    if (pStatus == 'confirmed' || pStatus == 'matched') {
      actions.add(
        _miniAction(
          'Arrived',
          Icons.pin_drop_outlined,
          () => _passengerAction('arrived', passengerId),
        ),
      );
    }
    if (pStatus == 'arrived') {
      actions.addAll([
        _miniAction(
          'Pick Up',
          Icons.person_add,
          () => _passengerAction('picked_up', passengerId),
        ),
        _miniAction(
          'No Show',
          Icons.person_off,
          () => _passengerAction('no_show', passengerId),
          color: AppColors.red400,
        ),
      ]);
    }
    if (pStatus == 'picked_up' || pStatus == 'in_progress') {
      actions.add(
        _miniAction(
          'Arriving',
          Icons.near_me,
          () => _passengerAction('arriving_dropoff', passengerId),
        ),
      );
    }
    if (pStatus == 'arriving_dropoff') {
      actions.add(
        _miniAction(
          'Drop Off',
          Icons.exit_to_app,
          () => _passengerAction('dropped_off', passengerId),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 6, children: actions);
  }

  Widget _miniAction(
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? AppColors.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _isActioning ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const Gap(4),
            Text(
              label,
              style: TextStyles.t2.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _passengerAction(String action, String passengerId) async {
    setState(() => _isActioning = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    bool success = false;

    switch (action) {
      case 'arrived':
        success = await notifier.arrivedAtPassengerPickup(_rideId, passengerId);
        break;
      case 'picked_up':
        success = await notifier.pickUpPassenger(_rideId, passengerId);
        break;
      case 'no_show':
        success = await notifier.markPassengerNoShow(_rideId, passengerId);
        break;
      case 'arriving_dropoff':
        success = await notifier.arrivedAtPassengerDropoff(
          _rideId,
          passengerId,
        );
        break;
      case 'dropped_off':
        success = await notifier.dropOffPassenger(_rideId, passengerId);
        break;
    }

    if (mounted) {
      setState(() => _isActioning = false);
      if (success) {
        _loadPassengersIfShared();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${action.replaceAll('_', ' ').capitalizeFirstChar()} successful',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action failed. Please try again.')),
        );
      }
    }
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
          if (_num(f['tip']) > 0) _fareRow('Tip', _num(f['tip'])),
          if (_num(f['waitingFare'] ?? f['waiting_fare']) > 0)
            _fareRow(
              'Waiting fare',
              _num(f['waitingFare'] ?? f['waiting_fare']),
            ),
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
                '₦${formatThousand(_num(f['totalFare'] ?? f['total_fare']))}',
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
  // Bottom actions – lifecycle buttons
  // ---------------------------------------------------------------------------

  Widget? _buildBottomActions() {
    if (_status == 'completed' ||
        _status == 'cancelled' ||
        _status == 'expired') {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canArrive)
              _actionButton(
                'Arrived at Pickup',
                AppColors.accent,
                Colors.white,
                _handleArrived,
              ),
            if (_canStart) ...[
              _actionButton(
                'Start Ride',
                AppColors.accent,
                Colors.white,
                _handleStartRide,
              ),
            ],
            if (_canComplete) ...[
              _actionButton(
                'Complete Ride',
                AppColors.green400,
                Colors.white,
                _handleComplete,
              ),
            ],
            if (_canCancel) ...[
              const Gap(10),
              _actionButton(
                'Cancel Ride',
                AppColors.red50,
                AppColors.red400,
                _handleCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String text, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isActioning ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.c10),
          ),
        ),
        child: _isActioning
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
              )
            : Text(
                text,
                style: TextStyles.t2.copyWith(
                  fontSize: FontSizes.s16,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle actions
  // ---------------------------------------------------------------------------

  Future<void> _handleArrived() async {
    setState(() => _isActioning = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    final success = await notifier.arrivedAtPickup(_rideId);
    _handleResult(success, 'arrived');
  }

  Future<void> _handleStartRide() async {
    // Prompt for OTP if required
    final otp = await _showOtpDialog();
    if (otp == null) return;

    setState(() => _isActioning = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    final success = await notifier.startRide(_rideId, otp: otp);
    _handleResult(success, 'in_progress');
  }

  Future<void> _handleComplete() async {
    setState(() => _isActioning = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    final success = await notifier.completeRide(_rideId);
    _handleResult(success, 'completed');
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text(
          'Are you sure you want to cancel this ride? This action cannot be undone.',
        ),
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

    setState(() => _isActioning = true);
    final notifier = ref.read(driverNotifierProvider.notifier);
    final success = await notifier.cancelRide(
      _rideId,
      reason: 'Driver cancelled',
    );
    if (mounted) {
      setState(() => _isActioning = false);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride cancelled.')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel. Try again.')),
        );
      }
    }
  }

  void _handleResult(bool success, String newStatus) {
    if (!mounted) return;
    setState(() {
      _isActioning = false;
      if (success) _ride['status'] = newStatus;
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride ${newStatus.replaceAll('_', ' ')} successfully.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Please try again.')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // OTP dialog for starting ride
  // ---------------------------------------------------------------------------

  Future<String?> _showOtpDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Ride OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask the passenger for the 4-digit code to start the ride.',
              style: TextStyles.t2.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                counterText: '',
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
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Confirm'),
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
