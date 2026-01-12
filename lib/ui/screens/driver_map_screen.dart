import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/driver_notifier.dart';
import '../../theme/app_colors.dart';
import '../../core/utils/map_helper.dart';
import '../widgets/ride_request_card.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    final driverState = ref.read(driverNotifierProvider);
    if (driverState.currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(driverState.currentLocation!.latLng),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverNotifierProvider);

    final currentLocation = driverState.currentLocation;
    final pendingRequests = driverState.pendingRequests;
    final isAvailable = driverState.isAvailable;

    Set<Marker> markers = {};

    if (currentLocation != null) {
      markers.add(
        MapHelper.createDriverMarker(currentLocation.latLng, 'current'),
      );
    }

    // Add markers for pending requests
    for (var request in pendingRequests) {
      markers.add(
        MapHelper.createPickupMarker(
          request.pickupLocation.latLng,
          id: 'request_${request.id}',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Switch(
            value: isAvailable,
            onChanged: (value) {
              ref.read(driverNotifierProvider.notifier).toggleAvailability();
            },
            activeColor: Colors.white,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target:
                  currentLocation?.latLng ?? const LatLng(37.7749, -122.4194),
              zoom: 14,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Status badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAvailable ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, blurRadius: 8),
                ],
              ),
              child: Text(
                isAvailable ? 'AVAILABLE' : 'OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Pending requests
          if (pendingRequests.isNotEmpty && isAvailable)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    return RideRequestCard(
                      request: request,
                      onAccept: () async {
                        final success = await ref
                            .read(driverNotifierProvider.notifier)
                            .acceptRideRequest(request.id);

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ride accepted! Navigate to pickup location.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !isAvailable
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(driverNotifierProvider.notifier).toggleAvailability();
              },
              label: const Text('Go Online'),
              icon: const Icon(Icons.play_arrow),
              backgroundColor: AppColors.success,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
