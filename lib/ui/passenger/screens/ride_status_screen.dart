import 'package:drup/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../providers/ride_notifier.dart';
import '../../../theme/app_colors.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/map_helper.dart';
import '../../../core/widgets/custom_button.dart';

class RideStatusScreen extends ConsumerStatefulWidget {
  const RideStatusScreen({super.key});

  @override
  ConsumerState<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends ConsumerState<RideStatusScreen> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateCamera();
  }

  void _updateCamera() {
    final rideState = ref.read(rideNotifierProvider);

    if (_mapController == null) return;

    final pickupLocation = rideState.pickupLocation;
    final destinationLocation = rideState.destinationLocation;

    if (pickupLocation != null && destinationLocation != null) {
      final bounds = MapHelper.calculateBounds([
        pickupLocation.latLng,
        destinationLocation.latLng,
      ]);

      MapHelper.animateCameraToBounds(_mapController!, bounds, padding: 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideNotifierProvider);

    final currentRide = rideState.currentRide;
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
      appBar: AppBar(
        title: const Text('Trip in Progress'),
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

          // Status indicator at top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Started',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Heading to your destination',
                            style: TextStyle(
                              fontSize: 14,
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
          ),

          // Complete trip button at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentRide != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fare:',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${currentRide.estimatedFare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomButton(
                    text: 'Complete Trip',
                    onPressed: () async {
                      final rideState = ref.read(rideNotifierProvider);
                      if (rideState.currentRide != null) {
                        await ref
                            .read(rideNotifierProvider.notifier)
                            .completeRide(rideState.currentRide!.id);
                      }

                      if (mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            title: const Text('Trip Completed!'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Total Fare: \$${currentRide?.estimatedFare.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Thank you for riding with us!',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.go(AppRoutes.homeRoute);
                                },
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    backgroundColor: AppColors.success,
                    icon: Icons.check_circle,
                  ),
                ],
              ),
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
