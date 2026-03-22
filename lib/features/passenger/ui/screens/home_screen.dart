import 'package:drup/di/notifiers.dart';
import 'package:drup/features/passenger/ui/widgets/location_dot_widget.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/features/passenger/ui/bottomsheets/schedule_form_bottomsheet.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_booking_bottomsheet.dart';
import 'package:drup/features/passenger/ui/widgets/passenger_app_drawer.dart';
import 'package:drup/features/passenger/ui/widgets/location_permission_bottom_sheet.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../provider/user_notifier.dart';
import '../../provider/ride_notifier.dart';
import '../../model/location_model.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/map_helper.dart';
import '../../../../di/providers.dart';
import '../../../../data/services/location_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _bottomSheetKey = GlobalKey();
  GoogleMapController? _mapController;
  ProviderSubscription<RideState>? _rideSub;
  ProviderSubscription<UserState>? _userSub;

  bool _isAtUserLocation = true;

  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  LocationModel? currentLocation;

  double _bottomSheetHeight = 0;

  // Center pin state
  bool _isDraggingMap = false;
  String? _pickedAddress;
  bool _isGeocodingCenter = false;
  LatLng? _lastCameraTarget;
  bool _locationReady = false;
  bool _isProgrammaticMove = false;
  late AnimationController _pinAnimController;
  late Animation<double> _pinTranslation;

  bool get _showCenterPin {
    final rideState = ref.read(rideNotifierProvider);
    return rideState.pickupLocation == null &&
        rideState.dropoffLocation == null;
  }

  @override
  void initState() {
    super.initState();

    // Pin lift/drop animation
    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pinTranslation = Tween<double>(begin: 0, end: -16).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _measureBottomSheetHeight();
    });

    _rideSub = ref.listenManual<RideState>(rideNotifierProvider, (prev, next) {
      _updateMapOverlays(next, allowCameraUpdate: true);
      _onRideStateChanged(prev, next);
    });

    _userSub = ref.listenManual<UserState>(userNotifierProvider, (prev, next) {
      final loc = next.currentLocation;
      if (loc == null) return;

      currentLocation = loc;

      // Only re-center if the location update came from GPS (not from pin picker)
      // and user hasn't panned away
      if (_mapController != null &&
          _isAtUserLocation &&
          prev?.currentLocation?.latLng != next.currentLocation?.latLng &&
          !_locationReady) {
        _animateCameraToUserLocation();
      }

      // keep marker refreshed
      _updateMapOverlays(
        ref.read(rideNotifierProvider),
        allowCameraUpdate: false,
      );
    });
  }

  void _measureBottomSheetHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _bottomSheetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final height = renderBox.size.height;
        if (height != _bottomSheetHeight && mounted) {
          setState(() => _bottomSheetHeight = height);
        }
      }
    });
  }

  // void _measureBookBottomSheetHeight() {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final RenderBox? renderBox =
  //         _bookBottomSheetKey.currentContext?.findRenderObject() as RenderBox?;
  //     if (renderBox != null) {
  //       final height = renderBox.size.height;
  //       if (height != _bookingBottomSheetHeight && mounted) {
  //         setState(() => _bookingBottomSheetHeight = height);
  //       }
  //     }
  //   });
  // }

  Future<void> _initializeLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final permissionStatus = await locationService.checkPermissionStatus();

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        await _fetchCurrentLocation();
        break;

      case LocationPermissionStatus.denied:
        _showLocationPermissionSheet();
        break;

      case LocationPermissionStatus.deniedForever:
        _showOpenSettingsSheet(isAppSettings: true);
        break;

      case LocationPermissionStatus.serviceDisabled:
        _showOpenSettingsSheet(isAppSettings: false);
        break;

      case LocationPermissionStatus.notDetermined:
        _showLocationPermissionSheet();
        break;
    }
  }

  Future<void> _fetchCurrentLocation() async {
    await ref.read(userNotifierProvider.notifier).updateUserLocation();
    final userState = ref.read(userNotifierProvider);

    if (userState.currentLocation != null) {
      currentLocation = userState.currentLocation;
      _lastCameraTarget = userState.currentLocation!.latLng;
      if (mounted) {
        setState(() {
          _pickedAddress = userState.currentLocation!.address;
        });
      }
      await _animateCameraToUserLocation();
      _locationReady = true;
    }
  }

  Future<void> _animateCameraToUserLocation() async {
    final userState = ref.read(userNotifierProvider);
    if (userState.currentLocation == null || _mapController == null) return;

    _isProgrammaticMove = true;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userState.currentLocation!.latLng,
          zoom: AppConstants.defaultCameraZoom,
        ),
      ),
    );
    _isProgrammaticMove = false;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // center once when map is ready
    _animateCameraToUserLocation();

    // apply ride-state camera logic once
    final rideState = ref.read(rideNotifierProvider);
    _onRideStateChanged(null, rideState);
  }

  void _onCameraMove(CameraPosition position) {
    _lastCameraTarget = position.target;

    final userState = ref.read(userNotifierProvider);
    final loc = userState.currentLocation;
    if (loc == null) return;

    final distance = _calculateDistance(
      position.target.latitude,
      position.target.longitude,
      loc.latitude,
      loc.longitude,
    );

    // Rough ~50m threshold
    final isNearUser = distance < 0.0005;

    if (_isAtUserLocation != isNearUser && mounted) {
      setState(() => _isAtUserLocation = isNearUser);
    }
  }

  void _onCameraMoveStarted() {
    if (!_showCenterPin || !_locationReady) return;
    if (_isProgrammaticMove) return;
    _pinAnimController.forward();
    if (!_isDraggingMap && mounted) {
      setState(() {
        _isDraggingMap = true;
        _pickedAddress = null;
      });
    }
  }

  Future<void> _onCameraIdle() async {
    if (!_showCenterPin || !_locationReady) return;
    if (_isProgrammaticMove) return;
    _pinAnimController.reverse();

    if (mounted) {
      setState(() => _isDraggingMap = false);
    }

    // Reverse-geocode the map center
    final center = _lastCameraTarget;
    if (center == null) return;

    setState(() => _isGeocodingCenter = true);

    final loc = LocationModel(
      latitude: center.latitude,
      longitude: center.longitude,
    );

    final mapsService = ref.read(googleMapsServiceProvider);
    final details = await mapsService.getLocationDetails(loc);

    if (!mounted) return;

    final address = details['address'];
    final name = details['name'];

    setState(() {
      _pickedAddress = name;
      _isGeocodingCenter = false;
    });

    // Update user's current location with the picked position
    final updatedLocation = LocationModel(
      latitude: center.latitude,
      longitude: center.longitude,
      name: name,
      address: address,
    );
    currentLocation = updatedLocation;
    ref.read(userNotifierProvider.notifier).setCurrentLocation(updatedLocation);
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;
    return dLat * dLat + dLon * dLon;
  }

  Future<void> _onMyLocationButtonPressed() async {
    final userState = ref.read(userNotifierProvider);
    if (userState.currentLocation != null && _mapController != null) {
      await _animateCameraToUserLocation();
      if (mounted) setState(() => _isAtUserLocation = true);
    }
  }

  // Camera logic based on ride state
  Future<void> _onRideStateChanged(RideState? prev, RideState next) async {
    if (!mounted) return;
    if (_mapController == null) return;

    if (!_isAtUserLocation) return;

    final hasPickup = next.pickupLocation != null;
    final hasDropoff = next.dropoffLocation != null;
    final hasRoute = next.routePoints.isNotEmpty;

    // Idle state: no pickup/dropoff
    if (!hasPickup && !hasDropoff) {
      final target = ref.read(userNotifierProvider).currentLocation?.latLng;
      if (target != null) {
        await _setZoom(14.5, target);
      }
      return;
    }

    // Pickup set but no dropoff yet: zoom closer to pickup
    if (hasPickup && !hasDropoff) {
      await _setZoom(16.8, next.pickupLocation!.latLng);
      return;
    }

    // Pickup + dropoff set: fit route bounds for best UX
    if (hasPickup && hasDropoff) {
      if (hasRoute) {
        await _animateCameraToRoute();
      } else {
        await _fitTwoPoints(
          next.pickupLocation!.latLng,
          next.dropoffLocation!.latLng,
        );
      }
    }
  }

  Future<void> _setZoom(double zoom, LatLng target) async {
    if (_mapController == null) return;
    _isProgrammaticMove = true;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
    _isProgrammaticMove = false;
  }

  Future<void> _fitTwoPoints(LatLng a, LatLng b) async {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      northeast: LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 120),
    );
  }

  Future<void> _animateCameraToRoute() async {
    final rideState = ref.read(rideNotifierProvider);

    if (rideState.pickupLocation == null || rideState.dropoffLocation == null) {
      return;
    }
    if (_mapController == null) return;

    final List<LatLng> allPoints = [
      rideState.pickupLocation!.latLng,
      rideState.dropoffLocation!.latLng,
      ...rideState.routePoints,
    ];

    final bounds = MapHelper.calculateBounds(allPoints);
    const double boundsPadding = 120.0;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, boundsPadding),
    );
  }

  /// Update map overlays when ride state changes
  void _updateMapOverlays(
    RideState rideState, {
    required bool allowCameraUpdate,
  }) {
    final pickupLocation = rideState.pickupLocation;
    final destinationLocation = rideState.dropoffLocation;
    final routePoints = rideState.routePoints;

    final newMarkers = <Marker>{};

    // pickup marker
    if (pickupLocation != null) {
      newMarkers.add(MapHelper.createPickupMarker(pickupLocation.latLng));
    }

    // destination marker
    if (destinationLocation != null) {
      newMarkers.add(
        MapHelper.createDestinationMarker(destinationLocation.latLng),
      );
    }

    final newPolylines = <Polyline>{};
    if (routePoints.isNotEmpty) {
      newPolylines.add(MapHelper.createRoutePolyline(routePoints));
    }

    final markersChanged = !_setEquals(markers, newMarkers);
    final polylinesChanged = !_setEquals(polylines, newPolylines);

    if ((markersChanged || polylinesChanged) && mounted) {
      setState(() {
        markers = newMarkers;
        polylines = newPolylines;
      });
    }
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const PassengerAppDrawer(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // Map Layer
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GoogleMap(
                mapType: MapType.normal,
                padding: EdgeInsets.only(bottom: _bottomSheetHeight * 0.9),
                onMapCreated: _onMapCreated,
                onCameraMoveStarted: _onCameraMoveStarted,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                initialCameraPosition: CameraPosition(
                  target:
                      currentLocation?.latLng ??
                      const LatLng(37.7749, -122.4194),
                  zoom: AppConstants.defaultCameraZoom,
                ),
                markers: markers,
                polylines: polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),

            // ── Center pin overlay (idle mode only) ──
            if (_showCenterPin)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: _bottomSheetHeight * 0.9,
                child: IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pinTranslation,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _pinTranslation.value),
                              child: child,
                            ),
                            child: Image.asset(
                              AppAssets.pickupIcon,
                              width: 31,
                              height: 48,
                            ),
                          ),
                          // Shadow dot
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isDraggingMap ? 12 : 6,
                            height: _isDraggingMap ? 12 : 6,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Address label (shown after pin drop) ──
            if (_showCenterPin &&
                (_pickedAddress != null) &&
                !_isGeocodingCenter)
              Positioned(
                left: 32,
                right: 32,
                bottom: _bottomSheetHeight + 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      LocationDotWidget(
                        bgColor: AppColors.green400,
                        isActive: true,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickedAddress ?? '',
                          style: TextStyles.h2.copyWith(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_isAtUserLocation)
              Positioned(
                right: 16,
                bottom:
                    _bottomSheetHeight +
                    (_showCenterPin &&
                            (_pickedAddress != null || _isGeocodingCenter)
                        ? 72
                        : 24),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _onMyLocationButtonPressed,
                  child: Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (notification) {
                  _measureBottomSheetHeight();
                  return true;
                },
                child: SizeChangedLayoutNotifier(
                  child: Container(
                    key: _bottomSheetKey,
                    child: RideBookingBottomsheet(
                      onWhereToTap: () async {
                        await context.push(AppRoutes.pickRideLocationRoute);
                      },
                      onScheduleRide: _scheduleRideBottomsheet,
                      onEditRide: () {},
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: rideState.hasActiveRoutes
                            ? Colors.white54
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, size: 24.0),
                          color: rideState.hasActiveRoutes
                              ? AppColors.accentLighter
                              : AppColors.accent,
                          onPressed: () {
                            if (rideState.hasActiveRoutes) return;
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                    ),
                    if (rideState.hasActiveRoutes)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 24.0),
                          color: AppColors.onAccent,
                          onPressed: () {
                            _showClearRoute(context);
                            _clearMapMarkers();
                          },
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

  void _scheduleRideBottomsheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleFormBottomsheet(
        onConfirm: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showLocationPermissionSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationPermissionBottomSheet(),
    ).then((_) {
      final userState = ref.read(userNotifierProvider);
      if (userState.currentLocation != null && _mapController != null) {
        currentLocation = userState.currentLocation;
        if (mounted) setState(() {});
        _animateCameraToUserLocation();
      }
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
                    : 'Please enable location services on your device to find rides near you.',
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

  void _clearMapMarkers() {
    if (!mounted) return;
    setState(() {
      markers = {};
      polylines = {};
    });
  }

  void _showClearRoute(BuildContext context) async {
    final rideState = ref.read(rideNotifierProvider);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Cancel ${rideState.rideType == RideType.delivery ? 'Delivery' : 'Ride'}',
          style: TextStyles.t3.copyWith(
            fontSize: FontSizes.s20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel the ${rideState.rideType == RideType.delivery ? 'delivery' : 'ride'}?',
          style: TextStyles.h3.copyWith(
            fontSize: FontSizes.s14,
            color: AppColors.surface500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'No',
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s16,
                color: AppColors.surface500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Yes',
              style: TextStyles.t1.copyWith(
                fontSize: FontSizes.s16,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _onMyLocationButtonPressed();
      ref.read(rideNotifierProvider.notifier).clearRoute();
    }
  }

  @override
  void dispose() {
    _pinAnimController.dispose();
    _rideSub?.close();
    _userSub?.close();
    _mapController?.dispose();
    super.dispose();
  }
}
