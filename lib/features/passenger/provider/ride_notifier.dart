import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/ride.dart';
import '../model/ride_api_models.dart';
import '../../drivers/model/ride_request.dart';
import '../model/location_model.dart';
import '../repository/ride_repository.dart';
import '../../../di/providers.dart';

class RideState {
  final Ride? currentRide;
  final BookedRide? bookedRide;
  final RideRequest? currentRequest;
  final List<LatLng> routePoints;
  final LocationModel? pickupLocation;
  final LocationModel? destinationLocation;
  final DateTime? scheduleTime;
  final bool isLoading;
  final String? errorMessage;
  final double? estimatedDistance;
  final int? estimatedDuration;
  final RideScheduleState rideScheduleState;
  final double? estimatedFare;
  final LocationModel? driverLocation;
  final RideSlot? selectedRideSlot;
  final List<VehicleEstimate> fareEstimates;
  final List<SavedCard> savedCards;
  final WalletBalanceResponse? walletBalance;
  final List<BookedRide> rideHistory;
  final List<RideSlot> rideSlots;

  RideState({
    this.currentRide,
    this.bookedRide,
    this.currentRequest,
    this.routePoints = const [],
    this.pickupLocation,
    this.destinationLocation,
    this.scheduleTime,
    this.isLoading = false,
    this.errorMessage,
    this.estimatedDistance,
    this.estimatedDuration,
    this.estimatedFare,
    this.driverLocation,
    this.selectedRideSlot,
    this.fareEstimates = const [],
    this.savedCards = const [],
    this.walletBalance,
    this.rideHistory = const [],
    this.rideSlots = const [],
    this.rideScheduleState = RideScheduleState.none,
  });

  RideState copyWith({
    Ride? currentRide,
    BookedRide? bookedRide,
    RideRequest? currentRequest,
    List<LatLng>? routePoints,
    LocationModel? pickupLocation,
    LocationModel? destinationLocation,
    DateTime? scheduleTime,
    bool? isLoading,
    String? errorMessage,
    double? estimatedDistance,
    int? estimatedDuration,
    double? estimatedFare,
    LocationModel? driverLocation,
    List<VehicleEstimate>? fareEstimates,
    List<SavedCard>? savedCards,
    WalletBalanceResponse? walletBalance,
    List<BookedRide>? rideHistory,
    RideSlot? selectedRideSlot,
    List<RideSlot>? rideSlots,
    RideScheduleState? rideScheduleState,
  }) {
    return RideState(
      currentRide: currentRide ?? this.currentRide,
      bookedRide: bookedRide ?? this.bookedRide,
      currentRequest: currentRequest ?? this.currentRequest,
      routePoints: routePoints ?? this.routePoints,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      driverLocation: driverLocation ?? this.driverLocation,
      fareEstimates: fareEstimates ?? this.fareEstimates,
      savedCards: savedCards ?? this.savedCards,
      selectedRideSlot: selectedRideSlot ?? this.selectedRideSlot,
      walletBalance: walletBalance ?? this.walletBalance,
      rideHistory: rideHistory ?? this.rideHistory,
      rideSlots: rideSlots ?? this.rideSlots,
      rideScheduleState: rideScheduleState ?? this.rideScheduleState,
    );
  }

  bool get hasActiveRoutes =>
      pickupLocation != null && destinationLocation != null;

  bool get hasActiveRide => currentRide != null || bookedRide != null;
}

enum RideScheduleState {
  searching,
  availableRides,
  rideBooked,
  connectingDriver,
  driverMatched,
  none,
}

class RideNotifier extends StateNotifier<RideState> {
  final Ref ref;
  StreamSubscription? _driverLocationSubscription;
  StreamSubscription? _activeRideSubscription;

  RideRepository get _repository => ref.read(rideRepositoryProvider);

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
    _activeRideSubscription = _repository.activeRideStream.listen((ride) {
      state = state.copyWith(currentRide: ride);

      if (ride != null && ride.driver?.currentLocation != null) {
        state = state.copyWith(driverLocation: ride.driver!.currentLocation);
      }
    });
  }

  void setScheduledDate(DateTime date) async {
    state = state.copyWith(scheduleTime: date);
  }

  void setRideScheduleState(RideScheduleState scheduleState) {
    state = state.copyWith(rideScheduleState: scheduleState);
  }

  void setSelectedRideSlot(RideSlot? slot) {
    state = state.copyWith(selectedRideSlot: slot);
  }

  // ===========================================================================
  // LOCATION MANAGEMENT
  // ===========================================================================

  Future<void> setPickupLocation(LocationModel location) async {
    state = state.copyWith(pickupLocation: location);
    if (state.destinationLocation != null) {
      Future.wait([calculateRoute(), calculateFare()]);
    }
  }

  Future<void> setDestinationLocation(LocationModel location) async {
    state = state.copyWith(destinationLocation: location);
    if (state.pickupLocation != null) {
      Future.wait([calculateRoute(), calculateFare()]);
    }
  }

  void clearPickupLocation() {
    state = RideState(
      currentRide: state.currentRide,
      bookedRide: state.bookedRide,
      currentRequest: state.currentRequest,
      routePoints: state.routePoints,
      pickupLocation: null,
      destinationLocation: state.destinationLocation,
      scheduleTime: state.scheduleTime,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      estimatedDistance: state.estimatedDistance,
      estimatedDuration: state.estimatedDuration,
      estimatedFare: state.estimatedFare,
      driverLocation: state.driverLocation,
      fareEstimates: state.fareEstimates,
      savedCards: state.savedCards,
      walletBalance: state.walletBalance,
      rideHistory: state.rideHistory,
    );
  }

  void clearDestinationLocation() {
    state = RideState(
      currentRide: state.currentRide,
      bookedRide: state.bookedRide,
      currentRequest: state.currentRequest,
      routePoints: state.routePoints,
      pickupLocation: state.pickupLocation,
      destinationLocation: null,
      scheduleTime: state.scheduleTime,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
      estimatedDistance: state.estimatedDistance,
      estimatedDuration: state.estimatedDuration,
      estimatedFare: state.estimatedFare,
      driverLocation: state.driverLocation,
      fareEstimates: state.fareEstimates,
      savedCards: state.savedCards,
      walletBalance: state.walletBalance,
      rideHistory: state.rideHistory,
    );
  }

  // ===========================================================================
  // ROUTE CALCULATION
  // ===========================================================================

  /// Calculate route polyline from Google Maps Directions API
  Future<bool> calculateRoute() async {
    if (state.pickupLocation == null || state.destinationLocation == null) {
      return false;
    }

    try {
      final mapsService = ref.read(googleMapsServiceProvider);
      final directions = await mapsService.getDirections(
        state.pickupLocation!,
        state.destinationLocation!,
      );

      if (directions != null) {
        final distance = directions['distance'] ?? 0.0;
        final duration = (directions['duration'] ?? 0.0).toInt();
        final polylinePointsString = directions['polylinePoints'] ?? '';

        // Decode polyline points
        final polylinePoints = polylinePointsString.isNotEmpty
            ? mapsService.decodePolyline(polylinePointsString)
            : <LatLng>[];

        state = state.copyWith(
          routePoints: polylinePoints,
          estimatedDistance: distance,
          estimatedDuration: duration,
        );
        return polylinePoints.isNotEmpty;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // ===========================================================================
  // FARE ESTIMATES
  // ===========================================================================

  /// Fetch fare estimates from API
  Future<bool> calculateFare() async {
    if (state.pickupLocation == null || state.destinationLocation == null) {
      state = state.copyWith(
        errorMessage: 'Please select pickup and destination',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = FareEstimateRequest(
        pickup: RideLocation(
          address: state.pickupLocation!.address ?? '',
          name: state.pickupLocation!.name ?? '',
          placeId: state.pickupLocation!.placeId ?? '',
          coordinates: RideCoordinates(
            latitude: state.pickupLocation!.latitude,
            longitude: state.pickupLocation!.longitude,
          ),
        ),
        dropoff: RideLocation(
          address: state.destinationLocation!.address ?? '',
          name: state.destinationLocation!.name ?? '',
          placeId: state.destinationLocation!.placeId ?? '',
          coordinates: RideCoordinates(
            latitude: state.destinationLocation!.latitude,
            longitude: state.destinationLocation!.longitude,
          ),
        ),
      );

      final response = await _repository.getFareEstimates(request);

      if (response.success && response.data != null) {
        state = state.copyWith(
          fareEstimates: response.data!.estimates,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to get fare estimates',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // RIDE BOOKING
  // ===========================================================================

  /// Get available slots for shared rides on a specific date
  Future<void> getAvailableSlots() async {
    if (state.pickupLocation == null ||
        state.destinationLocation == null ||
        state.scheduleTime == null) {
      state = state.copyWith(
        errorMessage: 'Please select pickup, destination, and date',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      rideScheduleState: RideScheduleState.searching,
      errorMessage: null,
    );

    try {
      final response = await _repository.getAvailableSlots(
        AvailableSlotsRequest(
          pickup: RideLocation(
            name: state.pickupLocation!.name ?? '',
            address: state.pickupLocation!.address ?? '',
            coordinates: RideCoordinates(
              latitude: state.pickupLocation!.latitude,
              longitude: state.pickupLocation!.longitude,
            ),
          ),
          dropoff: RideLocation(
            name: state.destinationLocation!.name ?? '',
            address: state.destinationLocation!.address ?? '',
            coordinates: RideCoordinates(
              latitude: state.destinationLocation!.latitude,
              longitude: state.destinationLocation!.longitude,
            ),
          ),
          scheduledTime: state.scheduleTime ?? DateTime.now(),
        ),
      );

      state = state.copyWith(isLoading: false);

      if (response.success && response.data != null) {
        state = state.copyWith(
          rideSlots: response.data!.slots,
          rideScheduleState: RideScheduleState.availableRides,
        );
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to get available slots',
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Book a ride with selected vehicle type
  Future<bool> bookRide({String? rideType, String? joinRideId}) async {
    if (state.pickupLocation == null ||
        state.destinationLocation == null ||
        state.scheduleTime == null) {
      state = state.copyWith(
        errorMessage: 'Please select pickup, destination, and date',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = BookRideRequest(
        pickup: RideLocation(
          name: state.pickupLocation!.name ?? '',
          address: state.pickupLocation!.address ?? '',
          coordinates: RideCoordinates(
            latitude: state.pickupLocation!.latitude,
            longitude: state.pickupLocation!.longitude,
          ),
        ),
        dropoff: RideLocation(
          name: state.destinationLocation!.name ?? '',
          address: state.destinationLocation!.address ?? '',
          coordinates: RideCoordinates(
            latitude: state.destinationLocation!.latitude,
            longitude: state.destinationLocation!.longitude,
          ),
        ),
        rideType: rideType,
        joinRideId: joinRideId,
        scheduledTime: state.scheduleTime,
      );

      final response = await _repository.bookRide(request);

      if (response.success && response.data != null) {
        state = state.copyWith(
          bookedRide: response.data!.ride,
          rideScheduleState: RideScheduleState.rideBooked,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to book ride',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Legacy request ride method for local testing
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
      final request = await _repository.createRideRequest(
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

  // ===========================================================================
  // PAYMENT
  // ===========================================================================

  /// Initialize payment for a ride
  Future<InitPaymentResponse?> initializePayment({
    required String rideId,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = InitPaymentRequest(
        rideId: rideId,
        paymentMethod: paymentMethod,
      );

      final response = await _repository.initializePayment(request);

      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false);
        return response.data;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to initialize payment',
          isLoading: false,
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return null;
    }
  }

  /// Pay with saved card
  Future<InitPaymentResponse?> payWithSavedCard({
    required String rideId,
    required String cardId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = PayWithSavedCardRequest(rideId: rideId, cardId: cardId);

      final response = await _repository.payWithSavedCard(request);

      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false);
        return response.data;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to process payment',
          isLoading: false,
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return null;
    }
  }

  /// Verify payment
  Future<bool> verifyPayment(String reference) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.verifyPayment(reference);

      if (response.success && response.data != null) {
        // Check if payment was successful based on status
        final isVerified = response.data!.status == 'success';
        state = state.copyWith(isLoading: false);
        return isVerified;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Payment verification failed',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // SAVED CARDS
  // ===========================================================================

  /// Fetch saved cards
  Future<bool> fetchSavedCards() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getSavedCards();

      if (response.success && response.data != null) {
        state = state.copyWith(
          savedCards: response.data!.cards,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to get saved cards',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Delete a saved card
  Future<bool> deleteSavedCard(String cardId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.deleteSavedCard(cardId);

      if (response.success) {
        // Remove card from state
        final updatedCards = state.savedCards
            .where((c) => c.id != cardId)
            .toList();
        state = state.copyWith(savedCards: updatedCards, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to delete card',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Set default card
  Future<bool> setDefaultCard(String cardId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.setDefaultCard(cardId);

      if (response.success) {
        // Update cards in state
        final updatedCards = state.savedCards.map((c) {
          return SavedCard(
            id: c.id,
            cardType: c.cardType,
            last4: c.last4,
            expMonth: c.expMonth,
            expYear: c.expYear,
            bank: c.bank,
            brand: c.brand,
            isDefault: c.id == cardId,
          );
        }).toList();
        state = state.copyWith(savedCards: updatedCards, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to set default card',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // WALLET
  // ===========================================================================

  /// Fetch wallet balance
  Future<bool> fetchWalletBalance() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getWalletBalance();

      if (response.success && response.data != null) {
        state = state.copyWith(walletBalance: response.data, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to get wallet balance',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Top up wallet
  Future<WalletTopUpResponse?> topUpWallet(double amount) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = WalletTopUpRequest(amount: amount);
      final response = await _repository.topUpWallet(request);

      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false);
        return response.data;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to top up wallet',
          isLoading: false,
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return null;
    }
  }

  // ===========================================================================
  // RIDE HISTORY
  // ===========================================================================

  /// Fetch ride history
  Future<bool> fetchRideHistory({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getRideHistory(
        page: page,
        limit: limit,
        status: status,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          rideHistory: response.data!.rides,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to get ride history',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // ACTIVE RIDE
  // ===========================================================================

  /// Fetch active ride from API
  Future<bool> fetchActiveRide() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getActiveRideFromApi();

      if (response.success && response.data != null) {
        state = state.copyWith(
          bookedRide: response.data!.ride,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message,
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Get ride details by ID
  Future<BookedRide?> getRideById(String rideId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getRideById(rideId);

      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false);
        return response.data;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to get ride details',
          isLoading: false,
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return null;
    }
  }

  // ===========================================================================
  // CANCEL RIDE
  // ===========================================================================

  /// Cancel a ride via API
  Future<bool> cancelRide(String rideId, {String? reason}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = CancelRideRequest(reason: reason ?? 'User cancelled');
      final response = await _repository.cancelRide(rideId, request);

      if (response.success) {
        // Clear the current ride state
        state = RideState();
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to cancel ride',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // RATE RIDE
  // ===========================================================================

  /// Rate a completed ride
  Future<bool> rateRide(
    String rideId, {
    required int rating,
    String? comment,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final request = RateRideRequest(rating: rating, comment: comment);

      final response = await _repository.rateRide(rideId, request);

      if (response.success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to rate ride',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // UTILITY
  // ===========================================================================

  Future<void> completeRide(String rideId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _repository.completeRide(rideId);
      state = RideState();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  void clearRoute() {
    state = RideState();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider instance
final rideNotifierProvider = StateNotifierProvider<RideNotifier, RideState>((
  ref,
) {
  return RideNotifier(ref);
});
