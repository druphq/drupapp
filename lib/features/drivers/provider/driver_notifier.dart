import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/driver.dart';
import '../../../data/models/ride.dart';
import '../../../data/models/ride_request.dart';
import '../../../data/models/location_model.dart';
import '../../../di/providers.dart';

class DriverState {
  final Driver? driver;
  final bool isAvailable;
  final LocationModel? currentLocation;
  final List<RideRequest> pendingRequests;
  final Ride? activeRide;
  final bool isLoading;
  final String? errorMessage;

  DriverState({
    this.driver,
    this.isAvailable = false,
    this.currentLocation,
    this.pendingRequests = const [],
    this.activeRide,
    this.isLoading = false,
    this.errorMessage,
  });

  DriverState copyWith({
    Driver? driver,
    bool? isAvailable,
    LocationModel? currentLocation,
    List<RideRequest>? pendingRequests,
    Ride? activeRide,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DriverState(
      driver: driver ?? this.driver,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLocation: currentLocation ?? this.currentLocation,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeRide: activeRide ?? this.activeRide,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  final Ref ref;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _requestsSubscription;
  StreamSubscription? _activeRideSubscription;

  DriverNotifier(this.ref) : super(DriverState()) {
    _listenToPendingRequests();
    _listenToActiveRide();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _requestsSubscription?.cancel();
    _activeRideSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadDriverProfile(String driverId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final driverRepository = ref.read(driverRepositoryProvider);
      final driver = await driverRepository.getDriverById(driverId);

      if (driver != null) {
        state = state.copyWith(driver: driver, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: 'Driver not found',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleAvailability() async {
    state = state.copyWith(isLoading: true);

    try {
      final newStatus = !state.isAvailable;
      final driverRepository = ref.read(driverRepositoryProvider);

      if (state.driver != null) {
        await driverRepository.updateDriverAvailability(
          state.driver!.id,
          newStatus,
        );

        state = state.copyWith(isAvailable: newStatus, isLoading: false);

        if (newStatus) {
          _startLocationTracking();
        } else {
          _stopLocationTracking();
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  void _listenToPendingRequests() {
    if (state.driver == null) return;

    // Note: This requires pendingRequestsStream in RideRepository
    // For MVP, you might want to poll instead or implement the stream
    // _requestsSubscription = rideRepository.pendingRequestsStream.listen((requests) {
    //   state = state.copyWith(pendingRequests: requests);
    // });
  }

  void _listenToActiveRide() {
    final rideRepository = ref.read(rideRepositoryProvider);

    _activeRideSubscription = rideRepository.activeRideStream.listen((ride) {
      state = state.copyWith(activeRide: ride);
    });
  }

  Future<bool> acceptRideRequest(String requestId) async {
    state = state.copyWith(isLoading: true);

    try {
      final rideRepository = ref.read(rideRepositoryProvider);

      if (state.driver != null) {
        final ride = await rideRepository.acceptRideRequest(
          requestId,
          state.driver!,
        );

        if (ride != null) {
          state = state.copyWith(
            activeRide: ride,
            pendingRequests: state.pendingRequests
                .where((r) => r.id != requestId)
                .toList(),
            isLoading: false,
          );
          return true;
        }
      }

      state = state.copyWith(
        errorMessage: 'Failed to accept ride',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> startTrip(String rideId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Note: For MVP, implement basic trip start logic
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> completeTrip(String rideId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Note: For MVP, implement basic trip completion logic
      state = state.copyWith(activeRide: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> updateLocation(LocationModel location) async {
    state = state.copyWith(currentLocation: location);

    if (state.driver != null && state.isAvailable) {
      try {
        final driverRepository = ref.read(driverRepositoryProvider);
        await driverRepository.updateDriverLocation(state.driver!.id, location);
      } catch (e) {
        // Log error but don't update state to avoid UI disruption
      }
    }
  }

  void _startLocationTracking() {
    final locationService = ref.read(locationServiceProvider);

    // Start location tracking first to initialize the stream
    final stream = locationService.startLocationTracking();

    _locationSubscription = stream.listen((location) {
      updateLocation(location);
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void clearState() {
    _stopLocationTracking();
    state = DriverState();
  }
}

// Provider instance
final driverNotifierProvider =
    StateNotifierProvider<DriverNotifier, DriverState>((ref) {
      return DriverNotifier(ref);
    });
