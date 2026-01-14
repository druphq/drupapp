import 'package:drup/theme/app_colors.dart';
import 'package:drup/ui/widgets/bottom_sheet_widget.dart';
import 'package:drup/ui/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/user_notifier.dart';
import '../../providers/ride_notifier.dart';
import '../../providers/providers.dart';
import '../../data/models/location_model.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/map_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  bool _selectingPickup = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final userState = ref.read(userNotifierProvider);

    if (userState.currentLocation == null) {
      await ref.read(userNotifierProvider.notifier).updateUserLocation();
    }

    final updatedState = ref.read(userNotifierProvider);
    if (updatedState.currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(updatedState.currentLocation!.latLng),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _initializeLocation();
  }

  void _onMapTap(LatLng position) async {
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

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    final rideState = ref.watch(rideNotifierProvider);

    final currentLocation = userState.currentLocation;
    final pickupLocation = rideState.pickupLocation;
    final destinationLocation = rideState.destinationLocation;

    Set<Marker> markers = {};

    if (pickupLocation != null) {
      markers.add(MapHelper.createPickupMarker(pickupLocation.latLng));
    }

    if (destinationLocation != null) {
      markers.add(
        MapHelper.createDestinationMarker(destinationLocation.latLng),
      );
    }

    Set<Polyline> polylines = {};
    if (rideState.routePoints.isNotEmpty) {
      polylines.add(MapHelper.createRoutePolyline(rideState.routePoints));
    }

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
              color: Theme.of(context).colorScheme.surface,
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
              icon: Icon(Icons.menu, color: AppColors.onAccent, size: 18.0),
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
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: GoogleMap(
              mapType: MapType.normal,
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
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

          // Bottom sheet with controls - positioned at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomSheetWidget(
              onWhereToTap: () {
                // Navigate to location search screen with slide up transition
                context.push(AppConstants.searchLocationsRoute);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
