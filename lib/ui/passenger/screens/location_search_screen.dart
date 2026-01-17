import 'dart:async';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/resources/app_strings.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../providers/ride_notifier.dart';
import '../../../providers/user_notifier.dart';
import '../../../data/models/location_model.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() =>
      _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final _currentLocationController = TextEditingController();
  final _destinationController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isCurrentLocationField = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCurrentLocation();
    });
  }

  void _setCurrentLocation() {
    final userState = ref.read(userNotifierProvider);
    if (userState.currentLocation != null) {
      final address = userState.currentLocation!.name ?? 'Pickup Location';
      _currentLocationController.text = address;
      ref
          .read(rideNotifierProvider.notifier)
          .setPickupLocation(userState.currentLocation!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _currentLocationController.dispose();
    _destinationController.dispose();
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
      final results = await mapsService.searchNigerianAirports(query);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching airports: $e')));
      }
    }
  }

  void _selectLocation(Map<String, dynamic> place) {
    final location = LocationModel(
      latitude: place['latitude'],
      longitude: place['longitude'],
      address: place['address'],
    );

    // Update the text field with selected airport
    if (_isCurrentLocationField) {
      _currentLocationController.text = place['name'];
      ref.read(rideNotifierProvider.notifier).setPickupLocation(location);
    } else {
      _destinationController.text = place['name'];
      ref.read(rideNotifierProvider.notifier).setDestinationLocation(location);
    }

    setState(() {
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xff253B80),
              Color(0xff253B80),
              Color(0xff5490D0),
              Color(0xff5C9EDC),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.scheduleYourRideTitleTxt,
                        textAlign: TextAlign.center,
                        style: TextStyles.t1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                    borderRadius: BorderRadius.circular(Corners.hMd),
                    color: AppColors.surface,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: Sizes.tfieldHeight,
                  alignment: Alignment.center,
                  child: TextField(
                    controller: _currentLocationController,
                    onChanged: (value) {
                      setState(() {
                        _isCurrentLocationField = true;
                      });
                      _onSearchChanged(value);
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      icon: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: 'Pickup Location',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
                      ),
                      suffixIcon: _currentLocationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                _currentLocationController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
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

              // Destination TextField
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Corners.hMd),
                    color: AppColors.surface,
                  ),
                  height: Sizes.tfieldHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _destinationController,
                    autofocus: true,
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
                      border: InputBorder.none,
                      icon: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.greyStrong, width: 2),
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: 'Where to?',
                      hintStyle: TextStyles.t2.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: FontSizes.s16,
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

              // Search results section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.only(top: 30.0),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                      ? SizedBox.shrink()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16.0,
                          ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Corners.md),
                                color: Colors.black.withValues(alpha: 0.2),
                              ),
                              child: ListTile(
                                leading: ImageIcon(
                                  AssetImage(AppAssets.flightIcon),
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                title: Text(
                                  place['name'] ?? '',
                                  style: TextStyles.t2.copyWith(
                                    color: Colors.white,
                                    fontSize: FontSizes.s15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  place['address'] ?? '',
                                  style: TextStyles.t2.copyWith(
                                    color: Colors.white70,
                                    fontSize: FontSizes.s13,
                                  ),
                                ),
                                onTap: () => _selectLocation(place),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
