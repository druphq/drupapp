import 'package:drup/ui/driver/widgets/driver_app_drawer.dart';
import 'package:drup/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../providers/driver_notifier.dart';
import '../../../theme/app_colors.dart';
import '../../../core/utils/map_helper.dart';
import '../../passenger/widgets/ride_request_card.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverHomeScreen> {
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
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const DriverAppDrawer(),
      // appBar: AppBar(
      //   systemOverlayStyle: SystemUiOverlayStyle.dark,
      //   backgroundColor: Colors.transparent,
      //   leading: Builder(
      //     builder: (context) => Container(
      //       margin: EdgeInsets.all(8.0),
      //       decoration: BoxDecoration(
      //         color: context.colorScheme.surface,
      //         shape: BoxShape.circle,
      //         boxShadow: [
      //           BoxShadow(
      //             color: Colors.black.withValues(alpha: 0.5),
      //             blurRadius: 6,
      //             offset: Offset(0, 2),
      //           ),
      //         ],
      //       ),
      //       child: IconButton(
      //         icon: Icon(Icons.menu, color: AppColors.onAccent, size: 24.0),
      //         onPressed: () {
      //           Scaffold.of(context).openDrawer();
      //         },
      //       ),
      //     ),
      //   ),
      //   actions: [
      //     Container(
      //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //       decoration: BoxDecoration(
      //         color: isAvailable ? AppColors.success : AppColors.error,
      //         borderRadius: BorderRadius.circular(20),
      //         boxShadow: const [
      //           BoxShadow(color: AppColors.shadow, blurRadius: 8),
      //         ],
      //       ),
      //       child: Text(
      //         isAvailable ? 'ONLINE' : 'OFFLINE',
      //         style: const TextStyle(
      //           color: Colors.white,
      //           fontWeight: FontWeight.bold,
      //         ),
      //       ),
      //     ),
      //     Gap(5.0),
      //     Switch(
      //       value: isAvailable,
      //       onChanged: (value) {
      //         ref.read(driverNotifierProvider.notifier).toggleAvailability();
      //       },
      //       activeThumbColor: Colors.white,
      //     ),
      //     const SizedBox(width: 8),
      //   ],
      // ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              mapType: MapType.normal,
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
            // Positioned(
            //   top: 16,
            //   left: 16,
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //     decoration: BoxDecoration(
            //       color: isAvailable ? AppColors.success : AppColors.error,
            //       borderRadius: BorderRadius.circular(20),
            //       boxShadow: const [
            //         BoxShadow(color: AppColors.shadow, blurRadius: 8),
            //       ],
            //     ),
            //     child: Text(
            //       isAvailable ? 'ONLINE' : 'OFFLINE',
            //       style: const TextStyle(
            //         color: Colors.white,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),

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

            // Menu button
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                      child: Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, size: 24.0),
                          color: AppColors.onAccent,
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.success
                                : AppColors.error,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            isAvailable ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Gap(5.0),
                        Switch(
                          value: isAvailable,
                          onChanged: (value) {
                            ref
                                .read(driverNotifierProvider.notifier)
                                .toggleAvailability();
                          },
                          activeThumbColor: Colors.white,
                        ),
                      ],
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
