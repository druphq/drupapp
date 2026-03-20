import 'package:drup/features/drivers/ui/widgets/driver_app_drawer.dart';
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
import '../../provider/driver_notifier.dart';
import '../../../../core/utils/map_helper.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    final loc = ref.read(driverNotifierProvider).currentLocation;
    if (loc != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(loc.latLng));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appStatus = ref.read(driverNotifierProvider).applicationStatus;
      final status = appStatus?['status'] as String?;
      if (status != 'active' && mounted) {
        context.push(AppRoutes.verifyDriverRoute);
      } else {
        ref.read(driverNotifierProvider.notifier).registerDeviceToken();
        // If already online, fetch active ride
        if (ref.read(driverNotifierProvider).isOnline) {
          ref.read(driverNotifierProvider.notifier).fetchActiveRide();
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Set<Marker> _buildMarkers(DriverState driverState) {
    final markers = <Marker>{};

    // Driver location
    final loc = driverState.currentLocation;
    if (loc != null) {
      markers.add(MapHelper.createDriverMarker(loc.latLng, 'current'));
    }

    // Active ride markers
    final active = driverState.activeRide;
    if (active != null) {
      _addRideMarkers(markers, active, prefix: 'active');
    } else {
      // Nearby ride pickup markers
      for (final ride in driverState.nearbyRides) {
        final rideId = (ride['_id'] ?? ride['id'] ?? '').toString();
        _addPickupMarker(markers, ride, id: 'request_$rideId');
      }
    }

    return markers;
  }

  void _addRideMarkers(
    Set<Marker> markers,
    Map<String, dynamic> ride, {
    String prefix = '',
  }) {
    final pickup = ride['pickup'] is Map
        ? ride['pickup'] as Map<String, dynamic>
        : null;
    final dropoff = ride['dropoff'] is Map
        ? ride['dropoff'] as Map<String, dynamic>
        : null;

    if (pickup != null) {
      final coords = _extractCoords(pickup);
      if (coords != null) {
        markers.add(
          MapHelper.createPickupMarker(coords, id: '${prefix}_pickup'),
        );
      }
    }
    if (dropoff != null) {
      final coords = _extractCoords(dropoff);
      if (coords != null) {
        markers.add(
          MapHelper.createDestinationMarker(coords, id: '${prefix}_dropoff'),
        );
      }
    }
  }

  void _addPickupMarker(
    Set<Marker> markers,
    Map<String, dynamic> ride, {
    String id = 'pickup',
  }) {
    final pickup = ride['pickup'] is Map
        ? ride['pickup'] as Map<String, dynamic>
        : null;
    if (pickup == null) return;

    final coords = _extractCoords(pickup);
    if (coords != null) {
      markers.add(MapHelper.createPickupMarker(coords, id: id));
    }
  }

  /// Extract LatLng from a location map.
  /// Handles both `{ coordinates: { coordinates: [lng, lat] } }` (API format)
  /// and `{ coordinates: [lng, lat] }` (socket format).
  LatLng? _extractCoords(Map<String, dynamic> location) {
    final coordsField = location['coordinates'];
    if (coordsField is Map) {
      final list = coordsField['coordinates'];
      if (list is List && list.length >= 2) {
        return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
      }
    }
    if (coordsField is List && coordsField.length >= 2) {
      return LatLng(
        (coordsField[1] as num).toDouble(),
        (coordsField[0] as num).toDouble(),
      );
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverNotifierProvider);
    final isOnline = driverState.isOnline;
    final activeRide = driverState.activeRide;
    final nearbyRides = driverState.nearbyRides;
    final loc = driverState.currentLocation;
    final markers = _buildMarkers(driverState);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const DriverAppDrawer(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // ── Map ──
            GoogleMap(
              mapType: MapType.normal,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: loc?.latLng ?? const LatLng(6.5244, 3.3792),
                zoom: 14,
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              padding: EdgeInsets.only(
                bottom: activeRide != null
                    ? 220
                    : (nearbyRides.isNotEmpty && isOnline ? 300 : 80),
              ),
            ),

            // ── Top bar: menu + toggle ──
            _buildTopBar(isOnline, driverState.isLoading),

            // ── My-location FAB ──
            Positioned(
              right: 16,
              bottom: activeRide != null
                  ? 240
                  : (nearbyRides.isNotEmpty && isOnline ? 320 : 100),
              child: FloatingActionButton.small(
                heroTag: 'myLoc',
                backgroundColor: Colors.white,
                onPressed: () {
                  if (loc != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(loc.latLng),
                    );
                  }
                },
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),

            // ── Bottom content ──
            if (!isOnline)
              _buildOfflineBanner()
            else if (activeRide != null)
              _buildActiveRideCard(activeRide)
            else if (nearbyRides.isNotEmpty)
              _buildNearbyRidesSheet(nearbyRides)
            else
              _buildWaitingIndicator(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar (menu + toggle)
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(bool isOnline, bool isLoading) {
    return Positioned(
      left: 16,
      right: 16,
      child: SafeArea(
        child: Row(
          children: [
            // Menu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, size: 22),
                  color: AppColors.onAccent,
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),
            const Spacer(),
            // Online toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Gap(8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: TextStyles.t2.copyWith(
                      fontSize: FontSizes.s14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(
                    height: 30,
                    child: Switch(
                      value: isOnline,
                      onChanged: isLoading
                          ? null
                          : (_) {
                              ref
                                  .read(driverNotifierProvider.notifier)
                                  .toggleAvailability();
                            },
                      activeThumbColor: AppColors.success,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
  // Offline banner
  // ---------------------------------------------------------------------------

  Widget _buildOfflineBanner() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Corners.c20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 36,
                color: AppColors.textLight,
              ),
              const Gap(10),
              Text(
                'You\'re offline',
                style: TextStyles.t1.copyWith(
                  fontSize: FontSizes.s18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                'Go online to start receiving ride requests.',
                style: TextStyles.t2.copyWith(
                  fontSize: FontSizes.s14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                    ref
                        .read(driverNotifierProvider.notifier)
                        .toggleAvailability();
                  },
                  child: Text(
                    'Go Online',
                    style: TextStyles.btnStyle.copyWith(
                      fontSize: FontSizes.s16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Waiting indicator (online but no rides)
  // ---------------------------------------------------------------------------

  Widget _buildWaitingIndicator() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Corners.c20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Searching for rides...',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      'You\'ll be notified when a request comes in.',
                      style: TextStyles.t2.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active ride card
  // ---------------------------------------------------------------------------

  Widget _buildActiveRideCard(Map<String, dynamic> ride) {
    final status = (ride['status'] ?? '').toString().toLowerCase();
    final rideType = (ride['rideType'] ?? ride['ride_type'] ?? '').toString();
    final isDelivery = rideType.toLowerCase() == 'delivery';

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

    // Fare
    final fare = ride['fare'] is Map
        ? ride['fare'] as Map<String, dynamic>
        : null;
    final totalFare =
        fare?['totalFare'] ?? fare?['total_fare'] ?? ride['totalFare'] ?? 0;

    // Passenger
    final passenger = ride['passenger'] is Map
        ? ride['passenger'] as Map<String, dynamic>
        : (ride['user'] is Map ? ride['user'] as Map<String, dynamic> : null);
    final passengerName = passenger != null
        ? '${passenger['firstName'] ?? ''} ${passenger['lastName'] ?? ''}'
              .trim()
        : '';

    // Status label
    String statusLabel;
    switch (status) {
      case 'matched':
      case 'confirmed':
      case 'accepted':
        statusLabel = 'Head to pickup';
        break;
      case 'arrived':
        statusLabel = 'Waiting for passenger';
        break;
      case 'in_progress':
      case 'picked_up':
        statusLabel = 'Trip in progress';
        break;
      default:
        statusLabel = status.capitalizeFirstChar();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Corners.c20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Corners.c20),
            child: InkWell(
              borderRadius: BorderRadius.circular(Corners.c20),
              onTap: () {
                context.push(AppRoutes.driverRideDetailRoute, extra: ride);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Status bar ──
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyles.t2.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor(status),
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

                    const Gap(12),

                    // ── Passenger ──
                    if (passengerName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.accent.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                passengerName[0].toUpperCase(),
                                style: TextStyles.t2.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                passengerName,
                                style: TextStyles.t2.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Route ──
                    _buildRoutePreview(pickupName, dropoffName),

                    const Gap(12),

                    // ── Action hint ──
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
                          context.push(
                            AppRoutes.driverRideDetailRoute,
                            extra: ride,
                          );
                        },
                        child: Text(
                          'View Details',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Nearby rides bottom sheet
  // ---------------------------------------------------------------------------

  Widget _buildNearbyRidesSheet(List<Map<String, dynamic>> rides) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.70,
      snap: true,
      snapSizes: const [0.15, 0.35, 0.70],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle + header ──
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final current = _sheetController.size;
                  _sheetController.animateTo(
                    current < 0.30 ? 0.70 : 0.15,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  alignment: Alignment.center,
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
                      const Gap(10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              'Ride Requests',
                              style: TextStyles.t1.copyWith(
                                fontSize: FontSizes.s16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(6),
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
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.push(
                                AppRoutes.driverRideRequestsRoute,
                              ),
                              child: Text(
                                'View All',
                                style: TextStyles.t2.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Ride cards ──
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: rides.length,
                  itemBuilder: (context, index) =>
                      _buildNearbyRideCard(rides[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNearbyRideCard(Map<String, dynamic> ride) {
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

    // Passenger
    final user = ride['user'] is Map
        ? ride['user'] as Map<String, dynamic>
        : null;
    final passengerName = user != null
        ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
        : null;

    // Scheduled?
    final isScheduled = ride['isScheduled'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: badges + fare ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
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
                    const Gap(6),
                    Icon(
                      isDelivery
                          ? Icons.local_shipping_outlined
                          : Icons.drive_eta,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const Gap(2),
                    if (vehicleType.isNotEmpty)
                      Text(
                        vehicleType.capitalizeFirstChar(),
                        style: TextStyles.t2.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (isScheduled) ...[
                      const Gap(6),
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
                      '₦${formatThousand((totalFare is num ? totalFare.toDouble() : 0))}',
                      style: TextStyles.t1.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const Gap(10),

                // ── Route: pickup → dropoff ──
                _buildRoutePreview(pickupName, dropoffName),

                const Gap(8),

                // ── Footer: distance, duration, passenger ──
                Row(
                  children: [
                    Icon(Icons.call_split, size: 14, color: AppColors.accent),
                    const Gap(4),
                    Text(
                      '${formatDistance((distance is num ? distance.toDouble() : 0))}, '
                      '${formatDuration(duration is int ? duration : (duration is num ? duration.toInt() : 0))}',
                      style: TextStyles.t2.copyWith(
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (passengerName != null && passengerName.isNotEmpty) ...[
                      const Spacer(),
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                      const Gap(3),
                      Text(
                        passengerName,
                        style: TextStyles.t2.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    const Gap(6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
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

  // ---------------------------------------------------------------------------
  // Shared route preview widget
  // ---------------------------------------------------------------------------

  Widget _buildRoutePreview(String pickupName, String dropoffName) {
    return IntrinsicHeight(
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
              const Icon(Icons.location_on, size: 16, color: AppColors.red400),
            ],
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickupName,
                  style: TextStyles.t2.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(10),
                Text(
                  dropoffName,
                  style: TextStyles.t2.copyWith(fontSize: 13),
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

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }
}
