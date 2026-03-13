import 'dart:async';
import 'package:drup/di/notifiers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/router/app_routes.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/features/passenger/ui/widgets/location_dot_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../di/providers.dart';
import '../../provider/ride_notifier.dart';
import '../../provider/user_notifier.dart';
import '../../model/location_model.dart';

class PickLocationScreen extends ConsumerStatefulWidget {
  const PickLocationScreen({super.key});

  @override
  ConsumerState<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends ConsumerState<PickLocationScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<LocationModel> _recentLocations = [];
  Timer? _debounceTimer;
  final focusNode1 = FocusNode();
  final focusNode2 = FocusNode();
  bool _isSearching = false;
  bool _isCurrentLocationField = false;
  bool _showCurrentLocationBtn = false;
  LocationModel? _selectedPickupLocation;
  LocationModel? _selectedDropOffLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCurrentLocationBtnVisiblity();
      _setCurrentLocation();
      _loadRecentLocations();
    });
  }

  Future<void> _loadRecentLocations() async {
    final recentLocationsService = ref.read(recentLocationsServiceProvider);
    final locations = await recentLocationsService.getRecentLocations();
    setState(() {
      _recentLocations = locations;
    });
  }

  Future<void> _saveRecentLocation(LocationModel location) async {
    final recentLocationsService = ref.read(recentLocationsServiceProvider);
    await recentLocationsService.addRecentLocation(location);
  }

  void _setCurrentLocationBtnVisiblity() {
    final userState = ref.read(userNotifierProvider);
    final address = userState.currentLocation!.name;
    _pickupController.addListener(() {
      setState(() {
        if ((_pickupController.text.isNotEmpty &&
                _pickupController.text == address) ||
            (_dropoffController.text.isNotEmpty &&
                _dropoffController.text == address)) {
          _showCurrentLocationBtn = false;
        } else {
          _showCurrentLocationBtn = true;
        }
      });
    });

    _dropoffController.addListener(() {
      setState(() {
        if ((_pickupController.text.isNotEmpty &&
                _pickupController.text == address) ||
            (_dropoffController.text.isNotEmpty &&
                _dropoffController.text == address)) {
          _showCurrentLocationBtn = false;
        } else {
          _showCurrentLocationBtn = true;
        }
      });
    });
  }

  // If the selected location matches either pickup or dropoff, we want to hide it from recent locations list.
  void hideLocationFromRecent(LocationModel location) {
    setState(() {
      _recentLocations.removeWhere(
        (loc) =>
            loc.latitude == location.latitude &&
            loc.longitude == location.longitude,
      );
    });
  }

  // Restore a location back to the recent locations list when the field is cleared
  void restoreLocationToRecent(LocationModel location) {
    // Check if location already exists in the list to avoid duplicates
    final exists = _recentLocations.any(
      (loc) =>
          loc.latitude == location.latitude &&
          loc.longitude == location.longitude,
    );
    if (!exists) {
      setState(() {
        _recentLocations.insert(0, location);
      });
    }
  }

  void _setCurrentLocation() {
    final userState = ref.read(userNotifierProvider);
    if (userState.currentLocation != null) {
      final address = userState.currentLocation!.name;
      _pickupController.text = address ?? '';

      setState(() {
        _selectedPickupLocation = userState.currentLocation!;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Show loading state immediately
    setState(() {
      _isSearching = true;
    });

    // Start new timer - only call API after 500ms of inactivity
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchAirports(query);
    });
  }

  Future<void> _searchAirports(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final mapsService = ref.read(googleMapsServiceProvider);
      final userState = ref.read(userNotifierProvider);
      final results = await mapsService.searchNigerianAddresses(
        query,
        userLocation: userState.currentLocation,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching addresses: $e')),
        );
      }
    }
  }

  void _selectLocation(Map<String, dynamic> place) {
    final location = LocationModel(
      latitude: place['latitude'],
      longitude: place['longitude'],
      name: place['name'],
      address: place['address'],
    );

    // Save to recent locations
    _saveRecentLocation(location);

    // Update the text field with selected address
    if (_isCurrentLocationField) {
      _pickupController.text = place['name'];
      setState(() {
        _selectedPickupLocation = location;
      });
    } else {
      _dropoffController.text = place['name'];
      setState(() {
        _selectedDropOffLocation = location;
      });
    }

    setState(() {
      _searchResults = [];
    });

    // Check if both locations are selected, then pop back to home
    _checkAndPopIfBothLocationsSelected();
  }

  void _selectRecentLocation(LocationModel location) {
    // Update the text field with selected address
    if (_isCurrentLocationField || focusNode1.hasFocus) {
      _pickupController.text = location.name ?? location.address ?? '';
      setState(() {
        _selectedPickupLocation = location;
      });
    } else {
      _dropoffController.text = location.name ?? location.address ?? '';
      setState(() {
        _selectedDropOffLocation = location;
      });
    }

    // Hide the selected location from recent locations list
    hideLocationFromRecent(location);

    // Check if both locations are selected, then pop back to home
    _checkAndPopIfBothLocationsSelected();
  }

  void _checkAndPopIfBothLocationsSelected() {
    if (_pickupController.text.isNotEmpty &&
        _dropoffController.text.isNotEmpty) {
      final rideRef = ref.read(rideNotifierProvider.notifier);
      rideRef.setPickupLocation(_selectedPickupLocation!);
      rideRef.setDropoffLocation(_selectedDropOffLocation!);

      context.pop(true);
    }
  }

  Future<void> _navigateToAirports(bool isPickup) async {
    final result = await context.push(
      '${AppRoutes.nigeriaAirportsRoute}?isPickup=$isPickup',
    );

    if (result != null && result is LocationModel) {
      // Update the text field with selected airport
      if (isPickup) {
        _pickupController.text = result.name ?? '';

        setState(() {
          _selectedPickupLocation = result;
        });
      } else {
        _dropoffController.text = result.name ?? '';
        setState(() {
          _selectedDropOffLocation = result;
        });
      }

      // Check if both locations are selected, then pop back to home
      _checkAndPopIfBothLocationsSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.accent),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.scheduleYourRideTitleTxt,
                      textAlign: TextAlign.center,
                      style: TextStyles.t1.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Gap(48),
                ],
              ),
            ),

            // Current Location TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Corners.lg),
                  color: AppColors.surface,
                ),
                height: Sizes.tfieldHeight,
                alignment: Alignment.center,
                child: TextField(
                  controller: _pickupController,
                  focusNode: focusNode1,
                  onChanged: (value) {
                    setState(() {
                      _isCurrentLocationField = true;
                    });
                    _onSearchChanged(value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.lg),
                      borderSide: BorderSide(color: AppColors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.lg),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.lg),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gap(16.0),
                        LocationDotWidget(
                          bgColor: AppColors.green400,
                          isActive: _pickupController.text.isNotEmpty,
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: 'Pickup Location',
                    hintStyle: TextStyles.t2.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: FontSizes.s16,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_pickupController.text.isNotEmpty &&
                            focusNode1.hasFocus)
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              // Restore the pickup location to recent list before clearing
                              final rideState = ref.read(rideNotifierProvider);
                              if (rideState.pickupLocation != null) {
                                restoreLocationToRecent(
                                  rideState.pickupLocation!,
                                );
                                ref
                                    .read(rideNotifierProvider.notifier)
                                    .clearPickupLocation();
                              }
                              _pickupController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          ),
                        IconButton(
                          onPressed: () => _navigateToAirports(true),
                          icon: ImageIcon(
                            AssetImage(AppAssets.flightIcon),
                            color: AppColors.accent,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: TextStyles.t2.copyWith(
                    color: AppColors.onAccent,
                    fontSize: FontSizes.s16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const Gap(16),

            // Dropoff TextField
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Corners.lg),
                  color: AppColors.surface,
                ),
                height: Sizes.tfieldHeight,
                alignment: Alignment.center,
                child: TextField(
                  controller: _dropoffController,
                  focusNode: focusNode2,
                  autofocus: true,
                  autocorrect: false,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    setState(() {
                      _isCurrentLocationField = false;
                    });
                    _onSearchChanged(value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.lg),
                      borderSide: BorderSide(color: AppColors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Corners.lg),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: 'Where to?',
                    hintStyle: TextStyles.t2.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: FontSizes.s16,
                    ),
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gap(16.0),
                        LocationDotWidget(
                          bgColor: AppColors.red400,
                          isActive: _dropoffController.text.isNotEmpty,
                        ),
                      ],
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_dropoffController.text.isNotEmpty &&
                            focusNode2.hasFocus)
                          IconButton(
                            icon: const Icon(
                              Icons.cancel,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              // Restore the dropoff location to recent list before clearing
                              final rideState = ref.read(rideNotifierProvider);
                              if (rideState.dropoffLocation != null) {
                                restoreLocationToRecent(
                                  rideState.dropoffLocation!,
                                );
                                ref
                                    .read(rideNotifierProvider.notifier)
                                    .clearDropoffLocation();
                              }
                              _dropoffController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          ),
                        IconButton(
                          onPressed: () => _navigateToAirports(false),
                          icon: ImageIcon(
                            AssetImage(AppAssets.flightIcon),
                            color: AppColors.accent,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: TextStyles.t2.copyWith(
                    color: AppColors.onAccent,
                    fontSize: FontSizes.s16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Search results section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _isSearching
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30.0),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Column(
                            children: [
                              ...ListTile.divideTiles(
                                color: Colors.grey.shade400,
                                tiles: [
                                  ...List.generate(_searchResults.length, (
                                    index,
                                  ) {
                                    final place = _searchResults[index];
                                    return ListTile(
                                      leading: ImageIcon(
                                        place['type']?.toLowerCase() ==
                                                'airport'
                                            ? const AssetImage(
                                                AppAssets.flightIcon,
                                              )
                                            : const AssetImage(
                                                AppAssets.locationIcon,
                                              ),
                                        color: AppColors.greyStrong,
                                        size: 18,
                                      ),
                                      title: Text(
                                        place['name'] ?? '',
                                        style: TextStyles.t2.copyWith(
                                          fontSize: FontSizes.s15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        place['address'] ?? '',
                                        style: TextStyles.t2.copyWith(
                                          fontSize: FontSizes.s13,
                                        ),
                                      ),
                                      onTap: () => _selectLocation(place),
                                    );
                                  }),

                                  // Show Cached Recent locations if there are any
                                  if (_searchResults.isEmpty &&
                                      _recentLocations.isNotEmpty)
                                    ..._recentLocations.map(
                                      (location) => ListTile(
                                        leading: ImageIcon(
                                          const AssetImage(
                                            AppAssets.locationIcon,
                                          ),
                                          color: AppColors.greyStrong,
                                          size: 18,
                                        ),
                                        title: Text(
                                          location.name ?? 'Unknown',
                                          style: TextStyles.t2.copyWith(
                                            fontSize: FontSizes.s15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          location.address ?? '',
                                          style: TextStyles.t2.copyWith(
                                            fontSize: FontSizes.s13,
                                          ),
                                        ),
                                        onTap: () =>
                                            _selectRecentLocation(location),
                                      ),
                                    ),

                                  // show current location button
                                  if (_showCurrentLocationBtn)
                                    Material(
                                      clipBehavior: Clip.hardEdge,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Corners.md,
                                        ),
                                      ),
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          final userState = ref.read(
                                            userNotifierProvider,
                                          );
                                          if (userState.currentLocation !=
                                              null) {
                                            final address =
                                                userState
                                                    .currentLocation!
                                                    .name ??
                                                'Current Location';

                                            if (focusNode1.hasFocus) {
                                              _pickupController.text = address;

                                              setState(() {
                                                _selectedPickupLocation =
                                                    userState.currentLocation!;
                                              });
                                            } else if (focusNode2.hasFocus) {
                                              _dropoffController.text = address;

                                              setState(() {
                                                _selectedDropOffLocation =
                                                    userState.currentLocation!;
                                              });
                                            }
                                            // Check if both locations are selected
                                            _checkAndPopIfBothLocationsSelected();
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.accent
                                                      .withValues(alpha: 0.1),
                                                ),
                                                padding: EdgeInsets.all(4),
                                                child: Icon(
                                                  Icons.my_location,
                                                  size: 24,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                              Gap(10.0),
                                              Text(
                                                'Current location',
                                                style: TextStyles.t1.copyWith(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
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
}
