import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

/// Modal bottom sheet displaying full ride request details with
/// Accept / Decline action buttons pinned at the bottom.
///
/// Call [RideDetailSheet.show] to present it.
class RideDetailSheet extends StatelessWidget {
  const RideDetailSheet({
    super.key,
    required this.ride,
    required this.onAccept,
    required this.onDecline,
    this.isActioning = false,
  });

  final Map<String, dynamic> ride;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isActioning;

  /// Show the sheet over the current screen. Returns after it is dismissed.
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> ride,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    bool isActioning = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RideDetailSheet(
        ride: ride,
        onAccept: onAccept,
        onDecline: onDecline,
        isActioning: isActioning,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  bool get _isDelivery =>
      (ride['rideType'] ?? ride['ride_type'] ?? '').toString().toLowerCase() ==
      'delivery';

  String get _rideType =>
      (ride['rideType'] ?? ride['ride_type'] ?? '').toString();

  String get _vehicleType =>
      (ride['vehicleType'] ?? ride['vehicle_type'] ?? '').toString();

  String get _rideNumber =>
      (ride['rideNumber'] ?? ride['ride_number'] ?? '').toString();

  Map<String, dynamic> get _pickup => ride['pickup'] is Map
      ? ride['pickup'] as Map<String, dynamic>
      : <String, dynamic>{};

  Map<String, dynamic> get _dropoff => ride['dropoff'] is Map
      ? ride['dropoff'] as Map<String, dynamic>
      : <String, dynamic>{};

  Map<String, dynamic>? get _fare =>
      ride['fare'] is Map ? ride['fare'] as Map<String, dynamic> : null;

  Map<String, dynamic>? get _passengerInfo {
    if (ride['passenger'] is Map) {
      return ride['passenger'] as Map<String, dynamic>;
    }
    if (ride['user'] is Map) return ride['user'] as Map<String, dynamic>;
    return null;
  }

  double _num(dynamic v) => (v is num ? v.toDouble() : 0.0);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final totalFare =
        _fare?['totalFare'] ?? _fare?['total_fare'] ?? ride['totalFare'] ?? 0;
    final distance =
        ride['estimatedDistance'] ??
        ride['estimated_distance'] ??
        ride['distance'] ??
        0;
    final duration =
        ride['estimatedDuration'] ??
        ride['estimated_duration'] ??
        ride['duration'] ??
        0;

    final pickupName = (_pickup['name'] ?? _pickup['address'] ?? 'Pickup')
        .toString();
    final dropoffName = (_dropoff['name'] ?? _dropoff['address'] ?? 'Dropoff')
        .toString();

    final passengerName = _passengerInfo != null
        ? '${_passengerInfo!['firstName'] ?? ''} ${_passengerInfo!['lastName'] ?? ''}'
              .trim()
        : '';

    final isScheduled = ride['isScheduled'] == true;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.4, 0.65, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Scrollable body ──
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    // ── Header: type + fare ──
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _isDelivery
                                ? AppColors.orange50
                                : AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isDelivery
                                    ? Icons.local_shipping_outlined
                                    : Icons.drive_eta,
                                size: 14,
                                color: _isDelivery
                                    ? AppColors.orange400
                                    : AppColors.accent,
                              ),
                              const Gap(4),
                              Text(
                                _rideType.capitalizeFirstChar(),
                                style: TextStyles.t2.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isDelivery
                                      ? AppColors.orange400
                                      : AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_vehicleType.isNotEmpty) ...[
                          const Gap(8),
                          Text(
                            _vehicleType.capitalizeFirstChar(),
                            style: TextStyles.t2.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (isScheduled) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 10,
                                  color: AppColors.orange400,
                                ),
                                const Gap(3),
                                Text(
                                  'Scheduled',
                                  style: TextStyles.t2.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.orange400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          '₦${formatThousand(_num(totalFare))}',
                          style: TextStyles.t1.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    if (_rideNumber.isNotEmpty) ...[
                      const Gap(8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _rideNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'Ref: $_rideNumber',
                              style: TextStyles.t2.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Gap(4),
                            Icon(
                              Icons.copy,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Gap(20),

                    // ── Route card ──
                    _buildRouteCard(pickupName, dropoffName),

                    const Gap(16),

                    // ── Trip stats ──
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.call_split,
                          formatDistance(_num(distance)),
                          'Distance',
                        ),
                        const Gap(12),
                        _buildStatChip(
                          Icons.timer_outlined,
                          formatDuration(
                            duration is int
                                ? duration
                                : (duration is num ? duration.toInt() : 0),
                          ),
                          'Duration',
                        ),
                      ],
                    ),

                    const Gap(16),

                    // ── Passenger info ──
                    if (passengerName.isNotEmpty) ...[
                      _buildSectionTitle('Passenger'),
                      const Gap(8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.accent.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              passengerName[0].toUpperCase(),
                              style: TextStyles.t2.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              passengerName,
                              style: TextStyles.t2.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                    ],

                    // ── Fare breakdown ──
                    if (_fare != null) ...[
                      _buildSectionTitle('Fare Breakdown'),
                      const Gap(8),
                      _buildFareBreakdown(),
                      const Gap(16),
                    ],

                    // ── Package info (delivery) ──
                    if (_isDelivery && ride['package'] is Map) ...[
                      _buildSectionTitle('Package'),
                      const Gap(8),
                      _buildPackageInfo(
                        ride['package'] as Map<String, dynamic>,
                      ),
                      const Gap(16),
                    ],

                    const Gap(40), // space for bottom actions
                  ],
                ),
              ),

              // ── Bottom actions ──
              _buildBottomActions(context),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard(String pickupName, String dropoffName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  height: 12,
                  width: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.pickupMarker,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.circle, color: Colors.white, size: 5),
                ),
                Expanded(child: Container(width: 2, color: AppColors.divider)),
                const Icon(
                  Icons.location_on,
                  size: 16,
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
                    'PICKUP',
                    style: TextStyles.t2.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    pickupName,
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(14),
                  Text(
                    'DROPOFF',
                    style: TextStyles.t2.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    dropoffName,
                    style: TextStyles.t2.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Corners.c20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const Gap(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyles.t1.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: TextStyles.t2.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyles.t1.copyWith(
        fontSize: FontSizes.s14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildFareBreakdown() {
    final baseFare = _fare?['baseFare'] ?? _fare?['base_fare'];
    final distFare = _fare?['distanceFare'] ?? _fare?['distance_fare'];
    final timeFare = _fare?['timeFare'] ?? _fare?['time_fare'];
    final totalFare = _fare?['totalFare'] ?? _fare?['total_fare'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        children: [
          if (baseFare != null)
            _fareRow('Base fare', '₦${formatThousand(_num(baseFare))}'),
          if (distFare != null)
            _fareRow('Distance fare', '₦${formatThousand(_num(distFare))}'),
          if (timeFare != null)
            _fareRow('Time fare', '₦${formatThousand(_num(timeFare))}'),
          if (totalFare != null) ...[
            const Divider(height: 16),
            _fareRow(
              'Total',
              '₦${formatThousand(_num(totalFare))}',
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyles.t2.copyWith(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo(Map<String, dynamic> package) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (package['description'] != null)
            Text(
              package['description'].toString(),
              style: TextStyles.t2.copyWith(fontSize: 13),
            ),
          if (package['size'] != null) ...[
            const Gap(4),
            Text(
              'Size: ${package['size']}',
              style: TextStyles.t2.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (package['fragile'] == true) ...[
            const Gap(4),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.orange400,
                ),
                const Gap(4),
                Text(
                  'Fragile',
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange400,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Decline
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: isActioning ? null : onDecline,
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
                  onPressed: isActioning ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Corners.c10),
                    ),
                  ),
                  child: isActioning
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
}
