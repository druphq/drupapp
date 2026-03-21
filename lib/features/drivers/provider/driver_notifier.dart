import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../di/providers.dart';
import '../../../network/socket_models.dart';
import '../../passenger/model/location_model.dart';
import '../model/driver.dart';
import '../model/vehicle.dart';

// =============================================================================
// DRIVER STATE
// =============================================================================

class DriverState {
  final Driver? driver;

  /// Whether the driver is currently online (maps to Driver.isOnline)
  final bool isOnline;

  final LocationModel? currentLocation;

  /// Nearby ride-request data returned by the API
  final List<Map<String, dynamic>> nearbyRides;

  /// The current active ride (from API)
  final Map<String, dynamic>? activeRide;

  /// Upcoming scheduled rides
  final List<Map<String, dynamic>> scheduledRides;

  /// Ride history
  final List<Map<String, dynamic>> rideHistory;

  /// Earnings summary
  final Map<String, dynamic>? earnings;

  /// Bank account details
  final Map<String, dynamic>? bankAccount;

  /// List of supported banks
  final List<dynamic> bankList;

  /// Application status snapshot (from /driver/status)
  final Map<String, dynamic>? applicationStatus;

  /// Verification status snapshot
  final Map<String, dynamic>? verificationStatus;

  /// Documents returned by GET /drivers/documents
  final List<DriverDocument> documents;

  final bool isLoading;
  final String? errorMessage;

  DriverState({
    this.driver,
    this.isOnline = false,
    this.currentLocation,
    this.nearbyRides = const [],
    this.activeRide,
    this.scheduledRides = const [],
    this.rideHistory = const [],
    this.earnings,
    this.bankAccount,
    this.bankList = const [],
    this.applicationStatus,
    this.verificationStatus,
    this.documents = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Convenience alias so existing UI code that reads `isAvailable` keeps working.
  bool get isAvailable => isOnline;

  DriverState copyWith({
    Driver? driver,
    bool? isOnline,
    LocationModel? currentLocation,
    List<Map<String, dynamic>>? nearbyRides,
    Map<String, dynamic>? activeRide,
    bool clearActiveRide = false,
    List<Map<String, dynamic>>? scheduledRides,
    List<Map<String, dynamic>>? rideHistory,
    Map<String, dynamic>? earnings,
    Map<String, dynamic>? bankAccount,
    bool clearBankAccount = false,
    List<dynamic>? bankList,
    Map<String, dynamic>? applicationStatus,
    Map<String, dynamic>? verificationStatus,
    List<DriverDocument>? documents,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DriverState(
      driver: driver ?? this.driver,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      nearbyRides: nearbyRides ?? this.nearbyRides,
      activeRide: clearActiveRide ? null : (activeRide ?? this.activeRide),
      scheduledRides: scheduledRides ?? this.scheduledRides,
      rideHistory: rideHistory ?? this.rideHistory,
      earnings: earnings ?? this.earnings,
      bankAccount: clearBankAccount ? null : (bankAccount ?? this.bankAccount),
      bankList: bankList ?? this.bankList,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// =============================================================================
// DRIVER NOTIFIER
// =============================================================================

class DriverNotifier extends StateNotifier<DriverState> {
  final Ref ref;
  StreamSubscription? _locationSubscription;
  StreamSubscription<RideNewEvent>? _rideNewSubscription;
  Timer? _nearbyRidesTimer;

  DriverNotifier(this.ref) : super(DriverState());

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _rideNewSubscription?.cancel();
    _nearbyRidesTimer?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // 1. DRIVER APPLICATION
  // ===========================================================================

  /// Apply as a driver.
  ///
  /// On success the API returns a driver-scoped token (stored by the
  /// repository) so that `/drivers/*` endpoints become accessible.
  /// We also refresh [applicationStatus] and [documents] so the UI can
  /// immediately transition to the documents-upload phase.
  Future<bool> applyAsDriver({
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    Map<String, dynamic>? vehicle,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.applyAsDriver(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        vehicle: vehicle,
      );

      if (response.success && response.data != null) {
        final driverData = response.data!['driver'] as Map<String, dynamic>?;
        if (driverData != null) {
          state = state.copyWith(
            driver: Driver.fromJson(driverData),
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }

        // Switch to driver role to obtain the driver-scoped token.
        // This makes `/drivers/*` endpoints (documents, etc.) accessible.
        await switchRole('driver');

        // Refresh application status so the verify screen shows updated info
        await fetchApplicationStatus();

        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Application failed',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Check the current driver application status
  Future<void> fetchApplicationStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getDriverApplicationStatus();

      if (response.success && response.data != null) {
        state = state.copyWith(
          applicationStatus: response.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to fetch status',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Switch user role between 'driver' and 'passenger'
  /// Caches tokens & user, and sets driver state from the response
  Future<bool> switchRole(String role) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.switchRole(role);

      if (response.success && response.data != null) {
        final data = response.data!;
        state = state.copyWith(
          driver: data.driverProfile,
          isOnline: data.driverProfile?.isOnline ?? false,
          isLoading: false,
        );
        return true;
      }

      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to switch role',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // 2. DRIVER PROFILE
  // ===========================================================================

  /// Load full driver profile from API
  Future<void> loadDriverProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getDriverProfile();

      if (response.success && response.data != null) {
        final driverData = response.data!['driver'] as Map<String, dynamic>?;
        if (driverData != null) {
          final driver = Driver.fromJson(driverData);
          state = state.copyWith(
            driver: driver,
            isOnline: driver.isOnline,
            isLoading: false,
          );
          return;
        }
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Driver not found',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Update driver profile fields
  Future<bool> updateDriverProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.updateDriverProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        dateOfBirth: dateOfBirth,
      );

      if (response.success && response.data != null) {
        final driverData = response.data!['driver'] as Map<String, dynamic>?;
        if (driverData != null) {
          state = state.copyWith(
            driver: Driver.fromJson(driverData),
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to update profile',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Upload profile photo
  Future<bool> uploadProfilePhoto(File photo) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.uploadDriverProfilePhoto(photo);

      if (response.success && response.data != null) {
        final photoUrl = response.data!['profilePhoto'] as String?;
        if (photoUrl != null && state.driver != null) {
          state = state.copyWith(
            driver: state.driver!.copyWith(profilePhoto: photoUrl),
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to upload photo',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update device token for push notifications
  Future<void> updateDeviceToken(
    String token, {
    String deviceType = 'ios',
  }) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.updateDriverDeviceToken(token, deviceType);
    } catch (_) {
      // Silent — non-critical
    }
  }

  /// Convenience: fetch the FCM token from Firebase and register it
  /// with the driver device-token endpoint.
  Future<void> registerDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final deviceType = defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';
        await updateDeviceToken(token, deviceType: deviceType);
      }
    } catch (_) {
      // Silent — non-critical
    }
  }

  // ===========================================================================
  // 3. VEHICLE MANAGEMENT
  // ===========================================================================

  /// Get current vehicle info and update driver state
  Future<void> fetchVehicleInfo() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getVehicleInfo();

      if (response.success && response.data != null) {
        final vehicleData = response.data!['vehicle'] as Map<String, dynamic>?;
        if (vehicleData != null && state.driver != null) {
          state = state.copyWith(
            driver: state.driver!.copyWith(
              vehicle: Vehicle.fromJson(vehicleData),
            ),
            isLoading: false,
          );
          return;
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Update vehicle information
  Future<bool> updateVehicleInfo({
    String? type,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.updateVehicleInfo(
        type: type,
        make: make,
        model: model,
        year: year,
        color: color,
        licensePlate: licensePlate,
      );

      if (response.success && response.data != null) {
        final vehicleData = response.data!['vehicle'] as Map<String, dynamic>?;
        if (vehicleData != null && state.driver != null) {
          state = state.copyWith(
            driver: state.driver!.copyWith(
              vehicle: Vehicle.fromJson(vehicleData),
            ),
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to update vehicle',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // 4. DOCUMENT MANAGEMENT
  // ===========================================================================

  /// Upload a single document immediately, then refresh the list.
  Future<bool> uploadDocument({
    required File documentFile,
    required String type,
    String? expiryDate,
  }) async {
    state = state.copyWith(errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.uploadDocument(
        documentFile: documentFile,
        type: type,
        expiryDate: expiryDate,
      );

      if (response.success) {
        // Refresh the documents list so status is up-to-date
        await fetchDocuments();
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to upload document',
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Fetch documents from GET /drivers/documents and store typed list in state.
  Future<void> fetchDocuments() async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getDocuments();

      if (response.success && response.data != null) {
        final rawDocs = response.data!['documents'] as List<dynamic>? ?? [];
        final docs = rawDocs
            .map((e) => DriverDocument.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(documents: docs);
      }
    } catch (_) {
      // Non-fatal — the UI can still show empty list
    }
  }

  // ===========================================================================
  // 5. VERIFICATION STATUS
  // ===========================================================================

  /// Fetch full verification status
  Future<void> fetchVerificationStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getVerificationStatus();

      if (response.success && response.data != null) {
        state = state.copyWith(
          verificationStatus: response.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to get verification status',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Whether the driver can go online (based on fetched verification data)
  bool get canGoOnline =>
      state.verificationStatus?['canGoOnline'] as bool? ?? false;

  // ===========================================================================
  // 6. GO ONLINE / OFFLINE
  // ===========================================================================

  /// Toggle driver online/offline status
  Future<void> toggleAvailability() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newStatus = !state.isOnline;
      final repo = ref.read(driverRepositoryProvider);

      final response = await repo.updateOnlineStatus(newStatus);

      if (response.success) {
        state = state.copyWith(isOnline: newStatus, isLoading: false);

        if (newStatus) {
          _startLocationTracking();
          _startNearbyRidesPolling();
          _startListeningForRides();
          fetchActiveRide();
        } else {
          _stopLocationTracking();
          _stopNearbyRidesPolling();
          _stopListeningForRides();
          state = state.copyWith(nearbyRides: [], clearActiveRide: true);
        }
      } else {
        state = state.copyWith(
          errorMessage: response.message ?? 'Failed to update status',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // ===========================================================================
  // 7. LOCATION UPDATES
  // ===========================================================================

  /// Push a location update to the API and update local state
  Future<void> updateLocation(LocationModel location) async {
    state = state.copyWith(currentLocation: location);

    if (state.driver != null && state.isOnline) {
      try {
        final repo = ref.read(driverRepositoryProvider);
        await repo.updateLocation(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } catch (_) {
        // Silent — avoid UI disruption for background location pings
      }
    }
  }

  void _startLocationTracking() {
    _locationSubscription?.cancel();
    final locationService = ref.read(locationServiceProvider);
    final stream = locationService.startLocationTracking();
    _locationSubscription = stream.listen((location) {
      updateLocation(location);
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  // ===========================================================================
  // 8. NEARBY RIDE REQUESTS
  // ===========================================================================

  /// Fetch nearby rides once (manual refresh)
  Future<void> fetchNearbyRides() async {
    if (state.currentLocation == null) return;

    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getNearbyRides(
        latitude: state.currentLocation!.latitude,
        longitude: state.currentLocation!.longitude,
      );

      if (response.success && response.data != null) {
        final rides =
            (response.data!['rides'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        state = state.copyWith(nearbyRides: rides);
      }
    } catch (_) {
      // Silent — will retry on next poll
    }
  }

  /// Start polling for nearby rides every [intervalSeconds] while online
  void _startNearbyRidesPolling({int intervalSeconds = 15}) {
    _nearbyRidesTimer?.cancel();
    fetchNearbyRides(); // immediate first fetch
    _nearbyRidesTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => fetchNearbyRides(),
    );
  }

  void _stopNearbyRidesPolling() {
    _nearbyRidesTimer?.cancel();
    _nearbyRidesTimer = null;
  }

  // ===========================================================================
  // 8b. SOCKET — REAL-TIME RIDE REQUESTS
  // ===========================================================================

  /// Start listening for `ride:new` socket events and merge them into
  /// [nearbyRides] so the driver sees them instantly.
  void _startListeningForRides() {
    _rideNewSubscription?.cancel();
    final socket = ref.read(socketClientProvider);
    _rideNewSubscription = socket.onRideNew.listen((event) {
      // Convert socket event to the same Map shape the nearby-rides API uses
      final rideMap = <String, dynamic>{
        '_id': event.rideId,
        'rideNumber': event.rideNumber,
        'rideType': event.rideType,
        'vehicleType': event.vehicleType,
        'pickup': event.pickup.toJson(),
        'dropoff': event.dropoff.toJson(),
        'fare': event.fare.toJson(),
        'estimatedDistance': event.estimatedDistance,
        'estimatedDuration': event.estimatedDuration,
        'isScheduled': event.isScheduled,
        'status': 'confirmed',
        if (event.package != null) 'package': event.package!.toJson(),
      };

      // Avoid duplicates by rideId
      final current = List<Map<String, dynamic>>.from(state.nearbyRides);
      if (!current.any((r) => (r['_id'] ?? r['id']) == event.rideId)) {
        current.insert(0, rideMap);
        state = state.copyWith(nearbyRides: current);
      }
    });
  }

  void _stopListeningForRides() {
    _rideNewSubscription?.cancel();
    _rideNewSubscription = null;
  }

  // ===========================================================================
  // 9. ACCEPT / DECLINE RIDE
  // ===========================================================================

  /// Accept a ride request
  Future<bool> acceptRide(String rideId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.acceptRide(rideId);

      if (response.success && response.data != null) {
        // Remove from nearby list, set as active ride
        state = state.copyWith(
          activeRide: response.data,
          nearbyRides: state.nearbyRides
              .where((r) => r['_id'] != rideId && r['id'] != rideId)
              .toList(),
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to accept ride',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Decline a ride request
  Future<bool> declineRide(String rideId, {String? reason}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.declineRide(rideId, reason: reason);

      if (response.success) {
        state = state.copyWith(
          nearbyRides: state.nearbyRides
              .where((r) => r['_id'] != rideId && r['id'] != rideId)
              .toList(),
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to decline ride',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // 10. RIDE LIFECYCLE — INDIVIDUAL RIDES
  // ===========================================================================

  /// Mark arrival at pickup location
  Future<bool> arrivedAtPickup(String rideId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.arrivedAtPickup(rideId);

      if (response.success && response.data != null) {
        state = state.copyWith(activeRide: response.data, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to mark arrival',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Start the ride (optionally with OTP verification)
  Future<bool> startRide(String rideId, {String? otp}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.startRide(rideId, otp: otp);

      if (response.success && response.data != null) {
        state = state.copyWith(activeRide: response.data, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to start ride',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Complete the ride (reached destination)
  Future<bool> completeRide(String rideId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.completeRide(rideId);

      if (response.success) {
        state = state.copyWith(clearActiveRide: true, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to complete ride',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // 11. SHARED RIDE PASSENGER MANAGEMENT
  // ===========================================================================

  /// Get the passenger list for a shared ride
  Future<List<Map<String, dynamic>>> getPassengers(String rideId) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getPassengers(rideId);

      if (response.success && response.data != null) {
        return (response.data!['passengers'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Mark arrival at a specific passenger's pickup
  Future<bool> arrivedAtPassengerPickup(
    String rideId,
    String passengerId,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.arrivedAtPassengerPickup(rideId, passengerId);

      if (response.success && response.data != null) {
        state = state.copyWith(activeRide: response.data, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to mark arrival',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Pick up a specific passenger
  Future<bool> pickUpPassenger(String rideId, String passengerId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.pickUpPassenger(rideId, passengerId);

      if (response.success && response.data != null) {
        state = state.copyWith(activeRide: response.data, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to pick up passenger',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Mark passenger as no-show
  Future<bool> markPassengerNoShow(String rideId, String passengerId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.markPassengerNoShow(rideId, passengerId);

      if (response.success && response.data != null) {
        state = state.copyWith(activeRide: response.data, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to mark no-show',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Mark arrival at a specific passenger's dropoff
  Future<bool> arrivedAtPassengerDropoff(
    String rideId,
    String passengerId,
  ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.arrivedAtPassengerDropoff(
        rideId,
        passengerId,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(activeRide: response.data, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to mark arrival at dropoff',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Drop off a specific passenger
  Future<bool> dropOffPassenger(String rideId, String passengerId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.dropOffPassenger(rideId, passengerId);

      if (response.success && response.data != null) {
        state = state.copyWith(activeRide: response.data, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to drop off passenger',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // 12. CANCEL RIDE (DRIVER)
  // ===========================================================================

  /// Cancel a ride as the driver (reason is required by API)
  Future<bool> cancelRide(String rideId, {required String reason}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.cancelRide(rideId, reason: reason);

      if (response.success) {
        state = state.copyWith(clearActiveRide: true, isLoading: false);
        return true;
      }
      state = state.copyWith(
        errorMessage: response.message ?? 'Failed to cancel ride',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ===========================================================================
  // 13. ACTIVE RIDE
  // ===========================================================================

  /// Check if driver has an active ride and load it
  Future<void> fetchActiveRide() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getActiveRide();

      if (response.success && response.data != null) {
        final rideData = response.data!['ride'] as Map<String, dynamic>?;
        state = state.copyWith(activeRide: rideData, isLoading: false);
      } else {
        state = state.copyWith(clearActiveRide: true, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // ===========================================================================
  // 14. SCHEDULED RIDES
  // ===========================================================================

  /// Fetch upcoming scheduled rides
  Future<void> fetchScheduledRides({
    int page = 1,
    int limit = 20,
    String status = 'upcoming',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getScheduledRides(
        page: page,
        limit: limit,
        status: status,
      );

      if (response.success && response.data != null) {
        final rides =
            (response.data!['rides'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        state = state.copyWith(scheduledRides: rides, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // ===========================================================================
  // 15. RIDE HISTORY
  // ===========================================================================

  /// Fetch driver ride history
  Future<void> fetchRideHistory({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getDriverRideHistory(
        page: page,
        limit: limit,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        final rides =
            (response.data!['rides'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        state = state.copyWith(rideHistory: rides, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // ===========================================================================
  // 16. EARNINGS
  // ===========================================================================

  /// Fetch driver earnings summary
  Future<void> fetchEarnings({DateTime? startDate, DateTime? endDate}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getEarnings(
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(earnings: response.data, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: response.message,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // ===========================================================================
  // 17. BANK ACCOUNT
  // ===========================================================================

  /// Fetch driver bank account details
  Future<void> fetchBankAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getBankAccount();

      if (response.success && response.data != null) {
        state = state.copyWith(bankAccount: response.data, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Update driver bank account
  Future<bool> updateBankAccount({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.updateBankAccount(
        bankName: bankName,
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountName: accountName,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(bankAccount: response.data, isLoading: false);
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

  /// Fetch list of supported banks
  Future<void> fetchBankList() async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.getBankList();

      if (response.success && response.data != null) {
        state = state.copyWith(bankList: response.data);
      }
    } catch (e) {
      debugPrint('Error fetching bank list: $e');
    }
  }

  /// Verify bank account number
  Future<Map<String, dynamic>?> verifyBankAccount({
    required String bankCode,
    required String accountNumber,
  }) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      final response = await repo.verifyBankAccount(
        bankCode: bankCode,
        accountNumber: accountNumber,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying bank account: $e');
      return null;
    }
  }

  // ===========================================================================
  // UTILITY
  // ===========================================================================

  /// Clear all state and stop background work
  void clearState() {
    _stopLocationTracking();
    _stopNearbyRidesPolling();
    state = DriverState();
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

final driverNotifierProvider =
    StateNotifierProvider<DriverNotifier, DriverState>((ref) {
      return DriverNotifier(ref);
    });
