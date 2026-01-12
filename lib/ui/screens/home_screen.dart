import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/user_notifier.dart';
import '../../providers/ride_notifier.dart';
import '../../providers/providers.dart';
import '../../data/models/location_model.dart';
import '../../theme/app_colors.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/map_helper.dart';
import '../widgets/custom_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
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

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    final mapsService = ref.read(googleMapsServiceProvider);
    final places = await mapsService.searchPlaces(query);

    if (places.isEmpty) {
      _showMessage('No results found');
      return;
    }

    if (!mounted) return;

    // Show results dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(place['name']),
                subtitle: Text(place['address']),
                onTap: () {
                  final location = LocationModel(
                    latitude: place['latitude'],
                    longitude: place['longitude'],
                    address: place['address'],
                  );

                  if (_selectingPickup) {
                    ref
                        .read(rideNotifierProvider.notifier)
                        .setPickupLocation(location);
                  } else {
                    ref
                        .read(rideNotifierProvider.notifier)
                        .setDestinationLocation(location);
                  }

                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(location.latLng),
                  );

                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      appBar: AppBar(
        title: const Text('Request Ride'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) {
                context.go(AppConstants.loginRoute);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
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
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _selectingPickup
                        ? 'Search pickup location'
                        : 'Search destination',
                    border: InputBorder.none,
                    icon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                  onSubmitted: _searchLocation,
                ),
              ),
            ),
          ),

          // Bottom sheet with controls
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
                  // Location selection toggle
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Pickup'),
                          selected: _selectingPickup,
                          onSelected: (selected) {
                            setState(() {
                              _selectingPickup = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Destination'),
                          selected: !_selectingPickup,
                          onSelected: (selected) {
                            setState(() {
                              _selectingPickup = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location info
                  if (pickupLocation != null)
                    _buildLocationInfo(
                      Icons.location_on,
                      'Pickup',
                      pickupLocation.address ?? 'Selected on map',
                    ),
                  if (destinationLocation != null) ...[
                    const SizedBox(height: 8),
                    _buildLocationInfo(
                      Icons.flag,
                      'Destination',
                      destinationLocation.address ?? 'Selected on map',
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Action button
                  if (pickupLocation != null && destinationLocation == null)
                    CustomButton(
                      text: 'Select Destination',
                      onPressed: () {
                        setState(() {
                          _selectingPickup = false;
                        });
                      },
                    )
                  else if (pickupLocation != null &&
                      destinationLocation != null)
                    CustomButton(
                      text: 'Calculate Fare',
                      onPressed: () async {
                        // Route is already calculated when locations are set
                        if (mounted) {
                          context.push(AppConstants.rideRequestRoute);
                        }
                      },
                      isLoading: rideState.isLoading,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(IconData icon, String label, String address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
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

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
