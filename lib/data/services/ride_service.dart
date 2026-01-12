import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/ride.dart';
import '../models/ride_request.dart';
import '../models/driver.dart';
import '../models/location_model.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/location_helper.dart';

class RideService {
  final _uuid = const Uuid();
  final List<RideRequest> _pendingRequests = [];
  final List<Ride> _activeRides = [];
  final StreamController<List<RideRequest>> _requestsController =
      StreamController<List<RideRequest>>.broadcast();
  final StreamController<Ride?> _activeRideController =
      StreamController<Ride?>.broadcast();

  /// Get stream of pending ride requests
  Stream<List<RideRequest>> get requestsStream => _requestsController.stream;

  /// Get stream of active ride
  Stream<Ride?> get activeRideStream => _activeRideController.stream;

  /// Create a new ride request
  Future<RideRequest> createRideRequest({
    required String userId,
    required String userName,
    required LocationModel pickupLocation,
    required LocationModel destinationLocation,
  }) async {
    // Calculate distance
    final distance = LocationHelper.calculateDistance(
      pickupLocation.latitude,
      pickupLocation.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    // Estimate time (40 km/h average speed)
    final estimatedTime = LocationHelper.estimateTravelTime(distance, 40);

    // Calculate fare
    final fare = _calculateFare(distance, estimatedTime);

    final request = RideRequest(
      id: _uuid.v4(),
      userId: userId,
      userName: userName,
      pickupLocation: pickupLocation,
      destinationLocation: destinationLocation,
      estimatedFare: fare,
      distanceKm: distance,
      estimatedDurationMin: estimatedTime,
      requestTime: DateTime.now(),
    );

    _pendingRequests.add(request);
    _requestsController.add(List.from(_pendingRequests));

    return request;
  }

  /// Accept ride request by driver
  Future<Ride?> acceptRideRequest(String requestId, Driver driver) async {
    try {
      final requestIndex = _pendingRequests.indexWhere(
        (r) => r.id == requestId,
      );

      if (requestIndex == -1) {
        return null;
      }

      final request = _pendingRequests[requestIndex];

      // Remove from pending requests
      _pendingRequests.removeAt(requestIndex);
      _requestsController.add(List.from(_pendingRequests));

      // Create active ride
      final ride = Ride(
        id: request.id,
        userId: request.userId,
        userName: request.userName,
        pickupLocation: request.pickupLocation,
        destinationLocation: request.destinationLocation,
        status: RideStatus.accepted,
        estimatedFare: request.estimatedFare,
        distanceKm: request.distanceKm,
        estimatedDurationMin: request.estimatedDurationMin,
        driver: driver,
        requestTime: request.requestTime,
        acceptTime: DateTime.now(),
      );

      _activeRides.add(ride);
      _activeRideController.add(ride);

      return ride;
    } catch (e) {
      print('Error accepting ride: $e');
      return null;
    }
  }

  /// Update ride status
  Future<Ride?> updateRideStatus(String rideId, RideStatus newStatus) async {
    try {
      final rideIndex = _activeRides.indexWhere((r) => r.id == rideId);

      if (rideIndex == -1) {
        return null;
      }

      final ride = _activeRides[rideIndex];
      Ride updatedRide;

      switch (newStatus) {
        case RideStatus.driverArriving:
          updatedRide = ride.copyWith(status: RideStatus.driverArriving);
          break;
        case RideStatus.tripStarted:
          updatedRide = ride.copyWith(
            status: RideStatus.tripStarted,
            startTime: DateTime.now(),
          );
          break;
        case RideStatus.tripCompleted:
          updatedRide = ride.copyWith(
            status: RideStatus.tripCompleted,
            endTime: DateTime.now(),
            actualFare: ride.estimatedFare,
          );
          break;
        case RideStatus.cancelled:
          updatedRide = ride.copyWith(status: RideStatus.cancelled);
          _activeRides.removeAt(rideIndex);
          _activeRideController.add(null);
          return updatedRide;
        default:
          updatedRide = ride.copyWith(status: newStatus);
      }

      _activeRides[rideIndex] = updatedRide;
      _activeRideController.add(updatedRide);

      return updatedRide;
    } catch (e) {
      print('Error updating ride status: $e');
      return null;
    }
  }

  /// Calculate fare based on distance and time
  double _calculateFare(double distanceKm, int durationMin) {
    final baseFare = AppConstants.baseFare;
    final perKm = distanceKm * AppConstants.perKmRate;
    final perMin = durationMin * AppConstants.perMinuteRate;
    final bookingFee = AppConstants.bookingFee;

    return double.parse(
      (baseFare + perKm + perMin + bookingFee).toStringAsFixed(2),
    );
  }

  /// Get pending requests
  List<RideRequest> getPendingRequests() {
    return List.from(_pendingRequests);
  }

  /// Get active ride by user ID
  Ride? getActiveRideByUserId(String userId) {
    try {
      return _activeRides.firstWhere((ride) => ride.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get active ride by driver ID
  Ride? getActiveRideByDriverId(String driverId) {
    try {
      return _activeRides.firstWhere((ride) => ride.driver?.id == driverId);
    } catch (e) {
      return null;
    }
  }

  /// Cancel ride request
  Future<bool> cancelRideRequest(String requestId) async {
    try {
      _pendingRequests.removeWhere((r) => r.id == requestId);
      _requestsController.add(List.from(_pendingRequests));
      return true;
    } catch (e) {
      print('Error cancelling ride request: $e');
      return false;
    }
  }

  /// Simulate driver movement
  Stream<LocationModel> simulateDriverMovement(
    LocationModel start,
    LocationModel end,
    int durationSeconds,
  ) async* {
    const updateInterval = 3; // seconds
    final totalSteps = durationSeconds ~/ updateInterval;

    for (int i = 0; i <= totalSteps; i++) {
      final fraction = i / totalSteps;
      final interpolated = LocationHelper.interpolatePosition(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
        fraction,
      );

      yield LocationModel(
        latitude: interpolated['latitude']!,
        longitude: interpolated['longitude']!,
      );

      if (i < totalSteps) {
        await Future.delayed(Duration(seconds: updateInterval));
      }
    }
  }

  void dispose() {
    _requestsController.close();
    _activeRideController.close();
  }
}
