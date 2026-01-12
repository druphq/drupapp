import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/ride.dart';
import '../data/models/ride_request.dart';
import '../data/models/location_model.dart';
import '../core/constants/constants.dart';
import 'providers.dart';

class RideState {
  final Ride? currentRide;
  final RideRequest? currentRequest;
  final List<LatLng> routePoints;
  final LocationModel? pickupLocation;
  final LocationModel? destinationLocation;
  final bool isLoading;
  final String? errorMessage;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final double? estimatedFare;
  final LocationModel? driverLocation;

  RideState({
    this.currentRide,
    this.currentRequest,
    this.routePoints = const [],
    this.pickupLocation,
    this.destinationLocation,
    this.isLoading = false,
    this.errorMessage,
    this.estimatedDistance,
    this.estimatedDuration,
    this.estimatedFare,
    this.driverLocation,
  });

  RideState copyWith({
    Ride? currentRide,
    RideRequest? currentRequest,
    List<LatLng>? routePoints,
    LocationModel? pickupLocation,
    LocationModel? destinationLocation,
    bool? isLoading,
    String? errorMessage,
    double? estimatedDistance,
    int? estimatedDuration,
    double? estimatedFare,
    LocationModel? driverLocation,
  }) {
    return RideState(
      currentRide: currentRide ?? this.currentRide,
      currentRequest: currentRequest ?? this.currentRequest,
      routePoints: routePoints ?? this.routePoints,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      driverLocation: driverLocation ?? this.driverLocation,
    );
  }

  bool get hasActiveRide => currentRide != null;
}

class RideNotifier extends StateNotifier<RideState> {
  final Ref ref;
  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _activeRideSubscription;

  RideNotifier(this.ref) : super(RideState()) {
    _listenToActiveRide();
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _activeRideSubscription?.cancel();
    super.dispose();
  }

  void _listenToActiveRide() {
    final rideRepository = ref.read(rideRepositoryProvider);

    _activeRideSubscription = rideRepository.activeRideStream.listen((ride) {
      state = state.copyWith(currentRide: ride);

      if (ride != null && ride.driver?.currentLocation != null) {
        state = state.copyWith(driverLocation: ride.driver!.currentLocation);
      }
    });
  }

  Future<void> setPickupLocation(LocationModel location) async {
    state = state.copyWith(pickupLocation: location);
    if (state.destinationLocation != null) {
      await _calculateRouteAndFare();
    }
  }

  Future<void> setDestinationLocation(LocationModel location) async {
    state = state.copyWith(destinationLocation: location);
    if (state.pickupLocation != null) {
      await _calculateRouteAndFare();
    }
  }

  Future<void> _calculateRouteAndFare() async {
    if (state.pickupLocation == null || state.destinationLocation == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final mapsService = ref.read(googleMapsServiceProvider);

      final directions = await mapsService.getDirections(
        state.pickupLocation!,
        state.destinationLocation!,
      );

      if (directions != null) {
        final distance = directions['distance'] ?? 0.0; // Already in km
        final duration = (directions['duration'] ?? 0.0)
            .toInt(); // Already in minutes

        // Decode polyline points
        final polylinePointsString = directions['polylinePoints'] ?? '';
        final polylinePoints = polylinePointsString.isNotEmpty
            ? mapsService.decodePolyline(polylinePointsString)
            : <LatLng>[];

        final fare = _calculateFare(distance, duration);

        state = state.copyWith(
          routePoints: polylinePoints,
          estimatedDistance: distance,
          estimatedDuration: duration,
          estimatedFare: fare,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  double _calculateFare(double distance, int duration) {
    return AppConstants.baseFare +
        (distance * AppConstants.perKmRate) +
        (duration * AppConstants.perMinuteRate) +
        AppConstants.bookingFee;
  }

  Future<bool> requestRide({
    required String userId,
    required String userName,
    required String paymentMethod,
  }) async {
    if (state.pickupLocation == null || state.destinationLocation == null) {
      state = state.copyWith(
        errorMessage: 'Please select pickup and destination',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final rideRepository = ref.read(rideRepositoryProvider);

      final request = await rideRepository.createRideRequest(
        userId: userId,
        userName: userName,
        pickupLocation: state.pickupLocation!,
        destinationLocation: state.destinationLocation!,
      );

      state = state.copyWith(currentRequest: request, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<bool> cancelRide(String rideId) async {
    state = state.copyWith(isLoading: true);

    try {
      final rideRepository = ref.read(rideRepositoryProvider);
      final success = await rideRepository.cancelRide(rideId);

      if (success) {
        state = RideState();
        return true;
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to cancel ride',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> completeRide(String rideId) async {
    state = state.copyWith(isLoading: true);

    try {
      final rideRepository = ref.read(rideRepositoryProvider);
      await rideRepository.completeRide(rideId);
      state = RideState();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  void clearRoute() {
    state = RideState();
  }
}

// Provider instance
final rideNotifierProvider = StateNotifierProvider<RideNotifier, RideState>((
  ref,
) {
  return RideNotifier(ref);
});
