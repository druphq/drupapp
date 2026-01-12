import '../models/ride.dart';
import '../models/ride_request.dart';
import '../models/driver.dart';
import '../models/location_model.dart';
import '../services/ride_service.dart';
import '../../core/constants/constants.dart';

class RideRepository {
  final RideService _rideService;

  RideRepository(this._rideService);

  /// Get stream of pending ride requests
  Stream<List<RideRequest>> get requestsStream => _rideService.requestsStream;

  /// Get stream of active ride
  Stream<Ride?> get activeRideStream => _rideService.activeRideStream;

  /// Create a new ride request
  Future<RideRequest> createRideRequest({
    required String userId,
    required String userName,
    required LocationModel pickupLocation,
    required LocationModel destinationLocation,
  }) async {
    return await _rideService.createRideRequest(
      userId: userId,
      userName: userName,
      pickupLocation: pickupLocation,
      destinationLocation: destinationLocation,
    );
  }

  /// Accept ride request
  Future<Ride?> acceptRideRequest(String requestId, Driver driver) async {
    return await _rideService.acceptRideRequest(requestId, driver);
  }

  /// Update ride status
  Future<Ride?> updateRideStatus(String rideId, RideStatus newStatus) async {
    return await _rideService.updateRideStatus(rideId, newStatus);
  }

  /// Get pending requests
  List<RideRequest> getPendingRequests() {
    return _rideService.getPendingRequests();
  }

  /// Get active ride by user ID
  Ride? getActiveRideByUserId(String userId) {
    return _rideService.getActiveRideByUserId(userId);
  }

  /// Get active ride by driver ID
  Ride? getActiveRideByDriverId(String driverId) {
    return _rideService.getActiveRideByDriverId(driverId);
  }

  /// Cancel ride request
  Future<bool> cancelRideRequest(String requestId) async {
    return await _rideService.cancelRideRequest(requestId);
  }

  /// Simulate driver movement
  Stream<LocationModel> simulateDriverMovement(
    LocationModel start,
    LocationModel end,
    int durationSeconds,
  ) {
    return _rideService.simulateDriverMovement(start, end, durationSeconds);
  }

  /// Get ride history (mock)
  Future<List<Ride>> getRideHistory(String userId) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  /// Cancel ride (complete the ride)
  Future<bool> cancelRide(String rideId) async {
    try {
      final ride = await updateRideStatus(rideId, RideStatus.cancelled);
      return ride != null;
    } catch (e) {
      print('Error cancelling ride: $e');
      return false;
    }
  }

  /// Complete ride
  Future<bool> completeRide(String rideId) async {
    try {
      final ride = await updateRideStatus(rideId, RideStatus.tripCompleted);
      return ride != null;
    } catch (e) {
      print('Error completing ride: $e');
      return false;
    }
  }
}
