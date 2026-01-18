import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/ui/passenger/bottomsheets/schedule_detail_bottomsheet.dart';
import 'package:drup/ui/passenger/widgets/bottom_sheet_widget.dart';
import 'package:drup/ui/passenger/widgets/app_drawer.dart';
import 'package:drup/ui/passenger/widgets/location_permission_bottom_sheet.dart';
import 'package:drup/ui/passenger/bottomsheets/ride_details_bottom_sheet.dart';
import 'package:drup/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../providers/user_notifier.dart';
import '../../../providers/ride_notifier.dart';
import '../../../providers/providers.dart';
import '../../../data/models/location_model.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/map_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  bool _selectingPickup = true;
  bool _isAtUserLocation = true;
  // bool _hasShownRideDetails = false;
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  LocationModel? currentLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final userState = ref.read(userNotifierProvider);

    if (userState.currentLocation == null ||
        userState.currentLocation!.address == null) {
      // Show location permission bottom sheet
      _showLocationPermissionSheet();
    } else {
      setState(() {
        currentLocation = userState.currentLocation;
      });

      // Update camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(userState.currentLocation!.latLng),
        );
      }
    }
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
      // After bottom sheet is closed, check if location is now available
      final userState = ref.read(userNotifierProvider);
      if (userState.currentLocation != null && _mapController != null) {
        setState(() {
          currentLocation = userState.currentLocation;
        });

        _mapController!.animateCamera(
          CameraUpdate.newLatLng(userState.currentLocation!.latLng),
        );
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _initializeLocation();
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      _isAtUserLocation = false;
    });

    final mapsService = ref.read(googleMapsServiceProvider);

    // Get address from coordinates
    final address = await mapsService.getAddressFromCoordinates(
      LocationModel(latitude: position.latitude, longitude: position.longitude),
    );

    final location = LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
    );

    if (_selectingPickup) {
      ref.read(rideNotifierProvider.notifier).setPickupLocation(location);
    } else {
      ref.read(rideNotifierProvider.notifier).setDestinationLocation(location);
    }
  }

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
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(userState.currentLocation!.latLng),
      );
      setState(() {
        _isAtUserLocation = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: Builder(
          builder: (context) => Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.menu, color: AppColors.onAccent, size: 24.0),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Google Map - stops at top of collapsed bottom sheet
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GoogleMap(
              mapType: MapType.normal,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.2,
              ),
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              onCameraMove: _onCameraMove,
              initialCameraPosition: CameraPosition(
                target:
                    currentLocation?.latLng ?? const LatLng(37.7749, -122.4194),
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
              bottom: MediaQuery.of(context).size.height * 0.22,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _onMyLocationButtonPressed,
                child: Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),

          // Bottom sheet with controls - positioned at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomSheetWidget(
              onWhereToTap: () async {
                // Navigate to location search screen with slide up transition
                final result = await context.push(
                  AppRoutes.searchLocationsRoute,
                );
                if (result == true) {
                  _drawDirectionOnMap();
                }
              },
              onScheduleRide: _scheduleRideBottomsheet,
            ),
          ),
        ],
      ),
    );
  }

  // fill scheduling details bottomsheet
  void _scheduleRideBottomsheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ScheduleDetailBottomSheet(), // this bottomsheet will contain the forms for the ride scheduling
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

    // Calculate bounds to show both markers
    final bounds = MapHelper.calculateBounds([
      rideState.pickupLocation!.latLng,
      rideState.destinationLocation!.latLng,
    ]);

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  _drawDirectionOnMap() {
    final rideState = ref.watch(rideNotifierProvider);

    final pickupLocation = rideState.pickupLocation;
    final destinationLocation = rideState.destinationLocation;

    // Check if both locations are set and show ride details
    if (pickupLocation != null && destinationLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateCameraToRoute();
      });
    }

    if (pickupLocation != null) {
      markers.add(MapHelper.createPickupMarker(pickupLocation.latLng));
    }

    if (destinationLocation != null) {
      markers.add(
        MapHelper.createDestinationMarker(destinationLocation.latLng),
      );
    }

    if (rideState.routePoints.isNotEmpty) {
      polylines.add(MapHelper.createRoutePolyline(rideState.routePoints));
    }

    // Trigger a function that calculates fare estimate based on distance
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
