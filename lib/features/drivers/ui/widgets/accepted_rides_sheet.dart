import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Bottom sheet listing the driver's accepted-but-not-started rides.
///
/// Each card has a **Start** button that triggers [onStart] to activate
/// the ride on the home screen.
class AcceptedRidesSheet extends StatelessWidget {
  const AcceptedRidesSheet({
    super.key,
    required this.rides,
    required this.onStart,
  });

  final List<Map<String, dynamic>> rides;
  final void Function(Map<String, dynamic> ride) onStart;

  /// Show the sheet. Returns after it is dismissed.
  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> rides,
    required void Function(Map<String, dynamic> ride) onStart,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AcceptedRidesSheet(rides: rides, onStart: onStart),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      snap: true,
      snapSizes: const [0.3, 0.50, 0.8],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Drag handle + header ──
              _buildHeader(),

              // ── Ride list ──
              Expanded(
                child: rides.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: AppColors.textLight,
                            ),
                            const Gap(12),
                            Text(
                              'No accepted rides',
                              style: TextStyles.t2.copyWith(
                                fontSize: FontSizes.s16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: rides.length,
                        itemBuilder: (_, i) =>
                            _buildRideCard(context, rides[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Accepted Rides',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rides.length}',
                    style: TextStyles.t2.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride) {
    final rideType = (ride['rideType'] ?? ride['ride_type'] ?? '').toString();
    final isDelivery = rideType.toLowerCase() == 'delivery';

    final fare = ride['fare'] is Map
        ? ride['fare'] as Map<String, dynamic>
        : null;
    final totalFare =
        fare?['totalFare'] ?? fare?['total_fare'] ?? ride['totalFare'] ?? 0;

    final pickup = ride['pickup'] is Map
        ? ride['pickup'] as Map<String, dynamic>
        : <String, dynamic>{};
    final dropoff = ride['dropoff'] is Map
        ? ride['dropoff'] as Map<String, dynamic>
        : <String, dynamic>{};
    final pickupName = (pickup['name'] ?? pickup['address'] ?? 'Pickup')
        .toString();
    final dropoffName = (dropoff['name'] ?? dropoff['address'] ?? 'Dropoff')
        .toString();

    final passenger = ride['passenger'] is Map
        ? ride['passenger'] as Map<String, dynamic>
        : (ride['user'] is Map ? ride['user'] as Map<String, dynamic> : null);
    final passengerName = passenger != null
        ? '${passenger['firstName'] ?? ''} ${passenger['lastName'] ?? ''}'
              .trim()
        : '';

    final distance =
        ride['estimatedDistance'] ??
        ride['estimated_distance'] ??
        ride['distance'] ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: type + fare ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDelivery
                      ? AppColors.orange50
                      : AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDelivery
                          ? Icons.local_shipping_outlined
                          : Icons.drive_eta,
                      size: 13,
                      color: isDelivery
                          ? AppColors.orange400
                          : AppColors.accent,
                    ),
                    const Gap(4),
                    Text(
                      rideType.capitalizeFirstChar(),
                      style: TextStyles.t2.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDelivery
                            ? AppColors.orange400
                            : AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (distance is num && distance > 0) ...[
                const Gap(6),
                Icon(
                  Icons.call_split,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
                const Gap(2),
                Text(
                  formatDistance(distance.toDouble()),
                  style: TextStyles.t2.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '₦${formatThousand((totalFare is num ? totalFare.toDouble() : 0))}',
                style: TextStyles.t1.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const Gap(10),

          // ── Route ──
          _buildRoutePreview(pickupName, dropoffName),

          if (passengerName.isNotEmpty) ...[
            const Gap(8),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  child: Text(
                    passengerName[0].toUpperCase(),
                    style: TextStyles.t2.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const Gap(6),
                Text(
                  passengerName,
                  style: TextStyles.t2.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const Gap(12),

          // ── Start button ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Corners.c10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // close sheet
                onStart(ride);
              },
              child: Text(
                'Start',
                style: TextStyles.t2.copyWith(
                  fontSize: FontSizes.s14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutePreview(String pickupName, String dropoffName) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                height: 10,
                width: 10,
                decoration: const BoxDecoration(
                  color: AppColors.pickupMarker,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Container(width: 1.5, color: AppColors.divider)),
              const Icon(Icons.location_on, size: 14, color: AppColors.red400),
            ],
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickupName,
                  style: TextStyles.t2.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(6),
                Text(
                  dropoffName,
                  style: TextStyles.t2.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
