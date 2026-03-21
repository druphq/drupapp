import 'package:drup/features/drivers/ui/widgets/accepted_rides_sheet.dart';
import 'package:drup/features/drivers/ui/widgets/driver_app_drawer.dart';
import 'package:drup/features/drivers/ui/widgets/incoming_ride_popup.dart';
import 'package:drup/features/drivers/ui/widgets/ride_detail_sheet.dart';
import 'package:drup/resources/app_assets.dart';
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
import '../../../../data/services/location_service.dart';
import '../../../../di/providers.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  GoogleMapController? _mapController;
  bool _hasCenteredOnDriver = false;
  BitmapDescriptor? _myLocationIcon;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateToDriverLocation();
  }

  /// Animate to the driver's current location once (first time map + location
  /// are both available).
  void _animateToDriverLocation() {
    if (_hasCenteredOnDriver || _mapController == null) return;
    final loc = ref.read(driverNotifierProvider).currentLocation;
    if (loc != null) {
      _hasCenteredOnDriver = true;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: loc.latLng, zoom: 15),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Load custom location icon
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(31, 48)),
      AppAssets.pickupIcon,
    ).then((icon) {
      if (!mounted) return;
      setState(() => _myLocationIcon = icon);
    });

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
        // Fetch driver's current location (with permission check)
        _initializeLocation();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Location Permission
  // ---------------------------------------------------------------------------

  Future<void> _initializeLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final permissionStatus = await locationService.checkPermissionStatus();

    if (!mounted) return;

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        await _fetchCurrentLocation();
        break;
      case LocationPermissionStatus.denied:
      case LocationPermissionStatus.notDetermined:
        _showLocationPermissionSheet();
        break;
      case LocationPermissionStatus.deniedForever:
        _showOpenSettingsSheet(isAppSettings: true);
        break;
      case LocationPermissionStatus.serviceDisabled:
        _showOpenSettingsSheet(isAppSettings: false);
        break;
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final location = await locationService.getCurrentLocation();
      if (location != null) {
        ref.read(driverNotifierProvider.notifier).updateLocation(location);
        _animateToDriverLocation();
      }
    } catch (_) {
      // Silently fail — location will be retried when going online
    }
  }

  void _showLocationPermissionSheet() {
    final locationService = ref.read(locationServiceProvider);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enable Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We need your location to show you on the map and receive nearby ride requests.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final status = await locationService.requestPermission();
                    if (!context.mounted) return;
                    if (status == LocationPermissionStatus.granted) {
                      Navigator.pop(context);
                    } else if (status ==
                        LocationPermissionStatus.deniedForever) {
                      Navigator.pop(context);
                      _showOpenSettingsSheet(isAppSettings: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Enable Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Skip for now',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // After sheet is dismissed, try fetching location
      _fetchCurrentLocation();
    });
  }

  void _showOpenSettingsSheet({required bool isAppSettings}) {
    final locationService = ref.read(locationServiceProvider);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  isAppSettings ? Icons.settings : Icons.location_off,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isAppSettings
                    ? 'Location Permission Required'
                    : 'Location Services Disabled',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isAppSettings
                    ? 'Location access was denied. Please enable it in your device settings to use Drup.'
                    : 'Please enable location services on your device to receive ride requests.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (isAppSettings) {
                      await locationService.openAppSettings();
                    } else {
                      await locationService.openLocationSettings();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Set<Marker> _buildMarkers(DriverState driverState) {
    final markers = <Marker>{};

    // Driver location
    final loc = driverState.currentLocation;
    if (loc != null && _myLocationIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: loc.latLng,
          icon: _myLocationIcon!,
        ),
      );
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
    final acceptedRides = driverState.acceptedRides;
    final loc = driverState.currentLocation;

    // Center on driver once location arrives (if map was ready first)
    if (!_hasCenteredOnDriver && loc != null) {
      _animateToDriverLocation();
    }
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
              padding: EdgeInsets.only(bottom: activeRide != null ? 220 : 80),
            ),

            // ── Top bar: menu + toggle ──
            _buildTopBar(isOnline, driverState.isLoading),

            // ── Incoming ride pop-in cards (max 2, slide from top) ──
            if (isOnline && activeRide == null && nearbyRides.isNotEmpty)
              IncomingRidePopups(
                rides: nearbyRides,
                onTap: _showRideDetail,
                onDismiss: (_) {},
              ),

            // ── My-location FAB ──
            Positioned(
              right: 16,
              bottom: activeRide != null ? 240 : 100,
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

            // ── Accepted-rides FAB (only when we have queued rides) ──
            if (isOnline && activeRide == null && acceptedRides.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 160,
                child: _buildAcceptedRidesFab(acceptedRides),
              ),

            // ── Bottom content ──
            if (!isOnline)
              _buildOfflineBanner()
            else if (activeRide != null)
              _buildActiveRideCard(activeRide)
            else
              _buildWaitingIndicator(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Ride detail bottom sheet (from pop-in tap)
  // ---------------------------------------------------------------------------

  void _showRideDetail(Map<String, dynamic> ride) {
    final rideId = (ride['_id'] ?? ride['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _RideDetailSheetWrapper(ride: ride, rideId: rideId, ref: ref),
    );
  }

  // ---------------------------------------------------------------------------
  // Accepted rides FAB with badge
  // ---------------------------------------------------------------------------

  Widget _buildAcceptedRidesFab(List<Map<String, dynamic>> acceptedRides) {
    return GestureDetector(
      onTap: () => _showAcceptedRidesSheet(acceptedRides),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.drive_eta, color: Colors.white, size: 24),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.red400,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${acceptedRides.length}',
                  style: TextStyles.t2.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptedRidesSheet(List<Map<String, dynamic>> rides) {
    AcceptedRidesSheet.show(
      context,
      rides: rides,
      onStart: (ride) {
        final rideId = (ride['_id'] ?? ride['id'] ?? '').toString();
        ref.read(driverNotifierProvider.notifier).startAcceptedRide(rideId);
      },
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(Corners.c20),
            ),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.explore_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nearby rides will show here',
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
    super.dispose();
  }
}

// =============================================================================
// Stateful wrapper for RideDetailSheet (manages isActioning state)
// =============================================================================

class _RideDetailSheetWrapper extends StatefulWidget {
  const _RideDetailSheetWrapper({
    required this.ride,
    required this.rideId,
    required this.ref,
  });

  final Map<String, dynamic> ride;
  final String rideId;
  final WidgetRef ref;

  @override
  State<_RideDetailSheetWrapper> createState() =>
      _RideDetailSheetWrapperState();
}

class _RideDetailSheetWrapperState extends State<_RideDetailSheetWrapper> {
  bool _isActioning = false;

  Future<void> _handleAccept() async {
    setState(() => _isActioning = true);
    final notifier = widget.ref.read(driverNotifierProvider.notifier);
    final success = await notifier.acceptRide(widget.rideId);

    if (mounted) {
      setState(() => _isActioning = false);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride accepted!')));
        Navigator.of(context).pop();
      } else {
        final err = widget.ref.read(driverNotifierProvider).errorMessage;
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
    final notifier = widget.ref.read(driverNotifierProvider.notifier);
    final success = await notifier.declineRide(
      widget.rideId,
      reason: reason.isNotEmpty ? reason : null,
    );

    if (mounted) {
      setState(() => _isActioning = false);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride declined.')));
        Navigator.of(context).pop();
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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RideDetailSheet(
      ride: widget.ride,
      isActioning: _isActioning,
      onAccept: _handleAccept,
      onDecline: _handleDecline,
    );
  }
}
