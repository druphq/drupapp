import 'package:drup/features/drivers/provider/driver_notifier.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:drup/utils/util_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Displays nearby ride requests available for the driver to accept.
class RideRequestScreen extends ConsumerStatefulWidget {
  const RideRequestScreen({super.key});

  @override
  ConsumerState<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends ConsumerState<RideRequestScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNearbyRides());
  }

  Future<void> _fetchNearbyRides() async {
    setState(() => _isLoading = true);
    await ref.read(driverNotifierProvider.notifier).fetchNearbyRides();
    if (mounted) setState(() => _isLoading = false);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final nearbyRides = ref.watch(
      driverNotifierProvider.select((s) => s.nearbyRides),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ride Requests',
          style: TextStyles.t1.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : nearbyRides.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _fetchNearbyRides,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: nearbyRides.length,
                itemBuilder: (context, index) =>
                    _buildRequestCard(nearbyRides[index]),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 80, color: AppColors.textLight),
          const Gap(16),
          Text(
            'No ride requests nearby',
            style: TextStyles.t2.copyWith(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(8),
          Text(
            'New requests will appear here when available.',
            style: TextStyles.t2.copyWith(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const Gap(24),
          TextButton.icon(
            onPressed: _fetchNearbyRides,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Request card
  // ---------------------------------------------------------------------------

  Widget _buildRequestCard(Map<String, dynamic> ride) {
    final rideType = (ride['rideType'] ?? ride['ride_type'] ?? '').toString();
    final isDelivery = rideType.toLowerCase() == 'delivery';
    final vehicleType = (ride['vehicleType'] ?? ride['vehicle_type'] ?? '')
        .toString();

    // Fare
    final fare = ride['fare'] is Map
        ? ride['fare'] as Map<String, dynamic>
        : null;
    final totalFare =
        fare?['totalFare'] ?? fare?['total_fare'] ?? ride['totalFare'] ?? 0;
    final formattedFare = '₦${formatThousand(totalFare)}';

    // Pickup / Dropoff
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

    // Distance & duration
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Corners.c20),
        child: InkWell(
          borderRadius: BorderRadius.circular(Corners.c20),
          onTap: () {
            context.push(AppRoutes.rideRequestDetailRoute, extra: ride);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: ride type + fare ──
                Row(
                  children: [
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
                        rideType.capitalizeFirstChar(),
                        style: TextStyles.t2.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Icon(
                      isDelivery
                          ? Icons.local_shipping_outlined
                          : Icons.drive_eta,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(4),
                    if (vehicleType.isNotEmpty)
                      Text(
                        vehicleType.capitalizeFirstChar(),
                        style: TextStyles.t2.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    Text(
                      formattedFare,
                      style: TextStyles.t1.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const Gap(14),

                // ── Route: pickup → dropoff ──
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
                              pickupName,
                              style: TextStyles.t2.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(14),
                            Text(
                              dropoffName,
                              style: TextStyles.t2.copyWith(fontSize: 14),
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

                // ── Distance / duration row ──
                Row(
                  children: [
                    Icon(Icons.call_split, size: 16, color: AppColors.accent),
                    const Gap(4),
                    Text(
                      '${formatDistance((distance is num ? distance.toDouble() : 0))}, ${formatDuration(duration is int ? duration : (duration is num ? duration.toInt() : 0))}',
                      style: TextStyles.t2.copyWith(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
