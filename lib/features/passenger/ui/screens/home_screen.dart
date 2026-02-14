import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/features/passenger/ui/bottomsheets/schedule_form_bottomsheet.dart';
import 'package:drup/features/passenger/ui/bottomsheets/ride_booking_bottomsheet.dart';
import 'package:drup/features/passenger/ui/widgets/plan_ride_bottomsheet.dart';
import 'package:drup/features/passenger/ui/widgets/app_drawer.dart';
import 'package:drup/features/passenger/ui/widgets/location_permission_bottom_sheet.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  bool _isAtUserLocation = true;
  bool _showRideSearchSheet = false;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  LocationModel? currentLocation;
  final GlobalKey _bottomSheetKey = GlobalKey();
  double _bottomSheetHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _measureBottomSheetHeight();
    });
  }

  void _measureBottomSheetHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _bottomSheetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final height = renderBox.size.height;
        if (height != _bottomSheetHeight) {
          setState(() {
            _bottomSheetHeight = height;
          });
        }
      }
    });
  }

  Future<void> _initializeLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final permissionStatus = await locationService.checkPermissionStatus();

    switch (permissionStatus) {
      case LocationPermissionStatus.granted:
        // Permission already granted - silently fetch location
        await _fetchCurrentLocation();
        break;

      case LocationPermissionStatus.denied:
        // Permission denied but can request again - show permission sheet
        _showLocationPermissionSheet();
        break;

      case LocationPermissionStatus.deniedForever:
        // Permission permanently denied - show settings prompt
        _showOpenSettingsSheet(isAppSettings: true);
        break;

      case LocationPermissionStatus.serviceDisabled:
        // Location services OFF - prompt to enable
        _showOpenSettingsSheet(isAppSettings: false);
        break;

      case LocationPermissionStatus.notDetermined:
        // First time - show permission sheet
        _showLocationPermissionSheet();
        break;
    }
  }

  /// Silently fetch current location when permission is granted
  Future<void> _fetchCurrentLocation() async {
    await ref.read(userNotifierProvider.notifier).updateUserLocation();
    final userState = ref.read(userNotifierProvider);

    if (userState.currentLocation != null) {
      setState(() {
        currentLocation = userState.currentLocation;
      });
      _animateCameraToUserLocation();
    }
  }

  /// Animate camera to user's current location, centered in visible area
  Future<void> _animateCameraToUserLocation() async {
    final userState = ref.read(userNotifierProvider);
    if (userState.currentLocation == null || _mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userState.currentLocation!.latLng,
          zoom: AppConstants.defaultCameraZoom,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Move camera to current location if already available
    _animateCameraToUserLocation();
  }

  // void _onMapTap(LatLng position) async {
  //   setState(() {
  //     _isAtUserLocation = false;
  //   });

  //   final mapsService = ref.read(googleMapsServiceProvider);

  //   // Get address from coordinates
  //   final address = await mapsService.getAddressFromCoordinates(
  //     LocationModel(latitude: position.latitude, longitude: position.longitude),
  //   );

  //   final location = LocationModel(
  //     latitude: position.latitude,
  //     longitude: position.longitude,
  //     address: address,
  //   );

  //   if (_selectingPickup) {
  //     ref.read(rideNotifierProvider.notifier).setPickupLocation(location);
  //   } else {
  //     ref.read(rideNotifierProvider.notifier).setDestinationLocation(location);
  //   }
  // }

  void _onCameraMove(CameraPosition position) {
    final userState = ref.read(userNotifierProvider);
    final currentLocation = userState.currentLocation;

    if (currentLocation != null) {
      // Calculate distance between camera position and user location
      final distance = _calculateDistance(
        position.target.latitude,
        position.target.longitude,
        currentLocation.latitude,
        currentLocation.longitude,
      );

      // If distance is very small (within ~50 meters), consider it at user location
      final isNearUser = distance < 0.0005;

      if (_isAtUserLocation != isNearUser) {
        setState(() {
          _isAtUserLocation = isNearUser;
        });
      }
    }
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
      setState(() {
        _isAtUserLocation = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch ride state to update map when route changes
    final rideState = ref.watch(rideNotifierProvider);

    // Update markers and polylines when route data changes
    _updateMapOverlays(rideState);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      // appBar:
      //  AppBar(
      //   systemOverlayStyle: SystemUiOverlayStyle.dark,
      //   leading: SizedBox.shrink(),
      // leading: Builder(
      //   builder: (context) => Container(
      //     margin: EdgeInsets.all(8.0),
      //     decoration: BoxDecoration(
      //       color: context.colorScheme.surface,
      //       shape: BoxShape.circle,
      //       boxShadow: [
      //         BoxShadow(
      //           color: Colors.black.withValues(alpha: 0.5),
      //           blurRadius: 6,
      //           offset: Offset(0, 2),
      //         ),
      //       ],
      //     ),
      //     child: IconButton(
      //       icon: Icon(Icons.menu, color: AppColors.onAccent, size: 24.0),
      //       onPressed: () {
      //         Scaffold.of(context).openDrawer();
      //       },
      //     ),
      //   ),
      // ),
      //   backgroundColor: Colors.transparent,
      //   iconTheme: const IconThemeData(color: Colors.black),
      // ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // Google Map - stops at top of collapsed bottom sheet
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GoogleMap(
                mapType: MapType.normal,
                padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                onMapCreated: _onMapCreated,
                // onTap: _onMapTap,
                onCameraMove: _onCameraMove,
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

            // Custom My Location Button
            if (!_isAtUserLocation)
              Positioned(
                right: 16,
                bottom: _bottomSheetHeight + 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _onMyLocationButtonPressed,
                  child: Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),

            // Bottom sheet with controls
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
                    child: PlanRideBottomsheet(
                      onWhereToTap: () async {
                        // Navigate to location search screen with slide up transition
                        final result = await context.push(
                          AppRoutes.pickLocationRoute,
                        );
                        if (result == true) {
                          // Animate camera to show route after returning
                          _animateCameraToRoute();
                        }
                      },
                      onCancelRide: _onMyLocationButtonPressed,
                      onScheduleRide: _scheduleRideBottomsheet,
                    ),
                  ),
                ),
              ),
            ),

            // Ride Search Draggable Bottom Sheet with backdrop
            if (_showRideSearchSheet)
              NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (notification) {
                  _measureBottomSheetHeight();
                  return true;
                },
                child: RideBookingBottomsheet(
                  onClose: () {
                    setState(() {
                      _showRideSearchSheet = false;
                    });
                  },
                ),
              ),

            // Menu button
            Positioned(
              left: 16,
              child: SafeArea(
                child: Container(
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
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, size: 24.0),
                      color: AppColors.onAccent,
                      onPressed: () => Scaffold.of(context).openDrawer(),
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

  // Animate camera to show both pickup and destination locations
  Future<void> _animateCameraToRoute() async {
    final rideState = ref.read(rideNotifierProvider);

    if (rideState.pickupLocation == null ||
        rideState.destinationLocation == null) {
      return;
    }

    if (_mapController == null) return;

    // Include route points for more accurate bounds if available
    final List<LatLng> allPoints = [
      rideState.pickupLocation!.latLng,
      rideState.destinationLocation!.latLng,
      ...rideState.routePoints,
    ];

    // Calculate bounds to show all points
    final bounds = MapHelper.calculateBounds(allPoints);

    // Padding for the bounds:
    const double boundsPadding = 80.0;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, boundsPadding),
    );
  }

  /// Update map overlays (markers and polylines) based on ride state
  void _updateMapOverlays(RideState rideState) {
    final pickupLocation = rideState.pickupLocation;
    final destinationLocation = rideState.destinationLocation;
    final routePoints = rideState.routePoints;

    // Build new markers set
    final newMarkers = <Marker>{};
    if (pickupLocation != null) {
      newMarkers.add(MapHelper.createPickupMarker(pickupLocation.latLng));
    }
    if (destinationLocation != null) {
      newMarkers.add(
        MapHelper.createDestinationMarker(destinationLocation.latLng),
      );
    }

    // Build new polylines set
    final newPolylines = <Polyline>{};
    if (routePoints.isNotEmpty) {
      newPolylines.add(MapHelper.createRoutePolyline(routePoints));
    }

    // Only update if changed to avoid unnecessary rebuilds
    if (!_setEquals(markers, newMarkers) ||
        !_setEquals(polylines, newPolylines)) {
      markers = newMarkers;
      polylines = newPolylines;
    }
  }

  /// Helper to compare sets
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  void _clearMapMarkers() {
    markers = {};
    polylines = {};
  }

  // fill scheduling details bottomsheet
  void _scheduleRideBottomsheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleFormBottomsheet(
        onConfirm: () {
          // Close schedule detail sheet
          Navigator.of(context).pop();

          // Wait for bottom sheet to close before showing the next one
          Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              _showRideSearchSheet = true;
            });
          });
        },
      ),
    );
  }

  // Show location permission bottom sheet
  void _showLocationPermissionSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationPermissionBottomSheet(),
    ).then((_) {
      // After bottom sheet is closed, check if location is now available
      final userState = ref.read(userNotifierProvider);
      if (userState.currentLocation != null && _mapController != null) {
        setState(() {
          currentLocation = userState.currentLocation;
        });
        // Center camera on current location with proper zoom
        _animateCameraToUserLocation();
      }
    });
  }

  /// Show bottom sheet prompting user to open settings
  /// [isAppSettings] - true for app settings (permission denied forever),
  ///                   false for location settings (service disabled)
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: Icon(
                  isAppSettings ? Icons.settings : Icons.location_off,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Title
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

              // Description
              Text(
                isAppSettings
                    ? 'Location access was denied. Please enable it in your device settings to use Drup.'
                    : 'Please enable location services on your device to find rides near you.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Open Settings Button
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

              // Skip Button
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
