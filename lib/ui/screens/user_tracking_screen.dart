import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/ride_notifier.dart';
import '../../theme/app_colors.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/map_helper.dart';
import '../../core/utils/location_helper.dart';
import '../widgets/driver_info_card.dart';
import '../widgets/custom_button.dart';

class UserTrackingScreen extends ConsumerStatefulWidget {
  const UserTrackingScreen({super.key});

  @override
  ConsumerState<UserTrackingScreen> createState() => _UserTrackingScreenState();
}

class _UserTrackingScreenState extends ConsumerState<UserTrackingScreen> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateCamera();
  }

  void _updateCamera() {
    final rideState = ref.read(rideNotifierProvider);

    if (_mapController == null) return;

    final pickupLocation = rideState.pickupLocation;
    final driverLocation = rideState.driverLocation;

    if (pickupLocation != null && driverLocation != null) {
      final bounds = MapHelper.calculateBounds([
        pickupLocation.latLng,
        driverLocation.latLng,
      ]);

      MapHelper.animateCameraToBounds(_mapController!, bounds, padding: 100);
    } else if (pickupLocation != null) {
      MapHelper.animateCameraToPosition(_mapController!, pickupLocation.latLng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    final currentRide = rideState.currentRide;
    final pickupLocation = rideState.pickupLocation;
    final driverLocation = rideState.driverLocation;
    final driver = currentRide?.driver;

    Set<Marker> markers = {};

    if (pickupLocation != null) {
      markers.add(MapHelper.createPickupMarker(pickupLocation.latLng));
    }

    if (driverLocation != null && driver != null) {
      markers.add(
        MapHelper.createDriverMarker(
          driverLocation.latLng,
          driver.id,
          driverName: driver.name,
        ),
      );
    }

    Set<Polyline> polylines = {};
    if (rideState.routePoints.isNotEmpty) {
      polylines.add(MapHelper.createRoutePolyline(rideState.routePoints));
    }

    // Calculate ETA and distance
    String? eta;
    String? distance;

    if (pickupLocation != null && driverLocation != null) {
      final distanceKm = LocationHelper.calculateDistance(
        driverLocation.latitude,
        driverLocation.longitude,
        pickupLocation.latitude,
        pickupLocation.longitude,
      );
      final timeMin = LocationHelper.estimateTravelTime(distanceKm, 40);

      distance = LocationHelper.formatDistance(distanceKm);
      eta = LocationHelper.formatDuration(timeMin);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver is on the way'),
        leading: const SizedBox(), // Remove back button
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target:
                  pickupLocation?.latLng ?? const LatLng(37.7749, -122.4194),
              zoom: 14,
            ),
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Driver info at bottom
          if (driver != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DriverInfoCard(driver: driver, eta: eta, distance: distance),

                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'Start Trip',
                          onPressed: () async {
                            // Trip should be started by driver, just navigate to status screen
                            if (mounted) {
                              context.go(AppConstants.rideStatusRoute);
                            }
                          },
                          backgroundColor: AppColors.success,
                          icon: Icons.play_arrow,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancel Ride'),
                                content: const Text(
                                  'Are you sure you want to cancel this ride?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && mounted) {
                              final rideState = ref.read(rideNotifierProvider);
                              if (rideState.currentRide != null) {
                                await ref
                                    .read(rideNotifierProvider.notifier)
                                    .cancelRide(rideState.currentRide!.id);
                              }
                              if (mounted) {
                                context.go(AppConstants.homeRoute);
                              }
                            }
                          },
                          child: const Text(
                            'Cancel Ride',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
