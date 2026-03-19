import 'dart:io';
import 'package:drup/features/auth/model/auth.dart';
import 'package:drup/features/auth/repository/auth_repository.dart';
import '../../../data/api/api_service.dart';
import '../../../data/services/driver_service.dart';

/// Repository handling all driver-related operations
/// Acts as the single source of truth for driver data in the app
class DriverRepository {
  final DriverService _driverService;
  final AuthRepository _authRepository;

  DriverRepository({
    DriverService? driverService,
    required AuthRepository authRepository,
  }) : _driverService = driverService ?? DriverService(),
       _authRepository = authRepository;

  // ===========================================================================
  // 1. DRIVER APPLICATION (from user mode)
  // ===========================================================================

  /// Apply to become a driver
  /// Creates a driver profile with `pending_verification` status
  Future<ApiResponse<Map<String, dynamic>>> applyAsDriver({
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    Map<String, dynamic>? vehicle,
  }) async {
    return await _driverService.applyAsDriver(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      vehicle: vehicle,
    );
  }

  /// Check driver application status
  Future<ApiResponse<Map<String, dynamic>>> getDriverApplicationStatus() async {
    return await _driverService.getDriverApplicationStatus();
  }

  // ===========================================================================
  // 2. SWITCH ROLE (User ↔ Driver)
  // ===========================================================================

  /// Switch between user and driver modes
  /// [role] - either 'user' or 'driver'
  /// Caches new tokens and user data, returns parsed response
  Future<ApiResponse<SwitchRoleResponse>> switchRole(String role) async {
    final response = await _driverService.switchRole(role);

    if (response.success && response.data != null) {
      final data = response.data!;
      // Store new tokens + user just like verifyOtp does
      await _authRepository.storeAuthData(
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
        user: data.user,
      );
    }

    return response;
  }

  // ===========================================================================
  // 3. DRIVER PROFILE
  // ===========================================================================

  /// Get driver profile (includes driver data and associated user info)
  Future<ApiResponse<Map<String, dynamic>>> getDriverProfile() async {
    return await _driverService.getDriverProfile();
  }

  /// Update driver profile
  Future<ApiResponse<Map<String, dynamic>>> updateDriverProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
  }) async {
    return await _driverService.updateDriverProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      dateOfBirth: dateOfBirth,
    );
  }

  /// Upload driver profile photo
  Future<ApiResponse<Map<String, dynamic>>> uploadDriverProfilePhoto(
    File photoFile,
  ) async {
    return await _driverService.uploadDriverProfilePhoto(photoFile);
  }

  /// Update driver device token for push notifications
  Future<ApiResponse<void>> updateDriverDeviceToken(
    String deviceToken,
    String deviceType,
  ) async {
    return await _driverService.updateDriverDeviceToken(
      deviceToken,
      deviceType,
    );
  }

  // ===========================================================================
  // 4. VEHICLE MANAGEMENT
  // ===========================================================================

  /// Get vehicle info
  Future<ApiResponse<Map<String, dynamic>>> getVehicleInfo() async {
    return await _driverService.getVehicleInfo();
  }

  /// Update vehicle info
  Future<ApiResponse<Map<String, dynamic>>> updateVehicleInfo({
    String? type,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
  }) async {
    return await _driverService.updateVehicleInfo(
      type: type,
      make: make,
      model: model,
      year: year,
      color: color,
      licensePlate: licensePlate,
    );
  }

  // ===========================================================================
  // 5. DOCUMENT MANAGEMENT
  // ===========================================================================

  /// Get all driver documents with verification status
  Future<ApiResponse<Map<String, dynamic>>> getDocuments() async {
    return await _driverService.getDocuments();
  }

  /// Upload a document
  /// [documentFile] - The document file (PDF, JPEG, PNG)
  /// [type] - Document type: profile_photo, drivers_license,
  ///          vehicle_photo_external, vehicle_photo_internal,
  ///          vehicle_registration, insurance, national_id,
  ///          vehicle_inspection
  /// [expiryDate] - Optional ISO 8601 expiry date
  Future<ApiResponse<Map<String, dynamic>>> uploadDocument({
    required File documentFile,
    required String type,
    String? expiryDate,
  }) async {
    return await _driverService.uploadDocument(
      documentFile: documentFile,
      type: type,
      expiryDate: expiryDate,
    );
  }

  // ===========================================================================
  // 6. VERIFICATION STATUS
  // ===========================================================================

  /// Get driver verification status
  /// Includes account status, profile status, vehicle/bank verification,
  /// document statuses, and whether the driver can go online
  Future<ApiResponse<Map<String, dynamic>>> getVerificationStatus() async {
    return await _driverService.getVerificationStatus();
  }

  // ===========================================================================
  // 7. GO ONLINE / OFFLINE
  // ===========================================================================

  /// Toggle driver online/offline status
  Future<ApiResponse<Map<String, dynamic>>> updateOnlineStatus(
    bool isOnline,
  ) async {
    return await _driverService.updateOnlineStatus(isOnline);
  }

  // ===========================================================================
  // 8. LOCATION UPDATES
  // ===========================================================================

  /// Update driver's current GPS location
  /// Call periodically (every 5–10 seconds) while online
  Future<ApiResponse<void>> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    return await _driverService.updateLocation(
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speed: speed,
    );
  }

  // ===========================================================================
  // 9. NEARBY RIDE REQUESTS
  // ===========================================================================

  /// Get ride requests near the driver's current location
  /// [radius] - Search radius in meters (default: 5000, max: 10000)
  Future<ApiResponse<Map<String, dynamic>>> getNearbyRides({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    return await _driverService.getNearbyRides(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  // ===========================================================================
  // 10. ACCEPT / DECLINE RIDE
  // ===========================================================================

  /// Accept a ride request (works for both on-demand and scheduled rides)
  /// Atomic first-accept-wins for scheduled rides
  Future<ApiResponse<Map<String, dynamic>>> acceptRide(String rideId) async {
    return await _driverService.acceptRide(rideId);
  }

  /// Decline a ride request
  Future<ApiResponse<void>> declineRide(String rideId, {String? reason}) async {
    return await _driverService.declineRide(rideId, reason: reason);
  }

  // ===========================================================================
  // 11. RIDE LIFECYCLE — INDIVIDUAL RIDES
  // ===========================================================================

  /// Mark arrival at pickup location (individual rides only)
  /// For shared rides, use [arrivedAtPassengerPickup] instead
  Future<ApiResponse<Map<String, dynamic>>> arrivedAtPickup(
    String rideId,
  ) async {
    return await _driverService.arrivedAtPickup(rideId);
  }

  /// Start ride
  /// [otp] - Optional 4-digit verification code from passenger
  /// For shared rides: call after all passengers are picked up
  Future<ApiResponse<Map<String, dynamic>>> startRide(
    String rideId, {
    String? otp,
  }) async {
    return await _driverService.startRide(rideId, otp: otp);
  }

  /// Complete ride (reached destination)
  /// For shared rides: call after all passengers are dropped off
  Future<ApiResponse<Map<String, dynamic>>> completeRide(String rideId) async {
    return await _driverService.completeRide(rideId);
  }

  // ===========================================================================
  // 12. SHARED RIDE PASSENGER MANAGEMENT
  // ===========================================================================

  /// Get list of passengers in a shared ride
  Future<ApiResponse<Map<String, dynamic>>> getPassengers(String rideId) async {
    return await _driverService.getPassengers(rideId);
  }

  /// Mark arrival at a specific passenger's pickup location
  Future<ApiResponse<Map<String, dynamic>>> arrivedAtPassengerPickup(
    String rideId,
    String passengerId,
  ) async {
    return await _driverService.arrivedAtPassengerPickup(rideId, passengerId);
  }

  /// Pick up a specific passenger (passenger has boarded)
  Future<ApiResponse<Map<String, dynamic>>> pickUpPassenger(
    String rideId,
    String passengerId,
  ) async {
    return await _driverService.pickUpPassenger(rideId, passengerId);
  }

  /// Mark a passenger as no-show
  Future<ApiResponse<Map<String, dynamic>>> markPassengerNoShow(
    String rideId,
    String passengerId,
  ) async {
    return await _driverService.markPassengerNoShow(rideId, passengerId);
  }

  /// Mark arrival at a specific passenger's dropoff location
  /// Ride must be `in_progress`
  Future<ApiResponse<Map<String, dynamic>>> arrivedAtPassengerDropoff(
    String rideId,
    String passengerId,
  ) async {
    return await _driverService.arrivedAtPassengerDropoff(rideId, passengerId);
  }

  /// Drop off a specific passenger at their destination
  Future<ApiResponse<Map<String, dynamic>>> dropOffPassenger(
    String rideId,
    String passengerId,
  ) async {
    return await _driverService.dropOffPassenger(rideId, passengerId);
  }

  // ===========================================================================
  // 13. CANCEL RIDE (DRIVER)
  // ===========================================================================

  /// Cancel a ride as driver
  /// [reason] - Required cancellation reason (min 1 char)
  /// Note: Ride goes back to `confirmed` for re-assignment, not `cancelled`
  Future<ApiResponse<Map<String, dynamic>>> cancelRide(
    String rideId, {
    required String reason,
  }) async {
    return await _driverService.cancelRide(rideId, reason: reason);
  }

  // ===========================================================================
  // 14. DRIVER ACTIVE RIDE
  // ===========================================================================

  /// Check if the driver has a current active ride
  /// Returns ride data or null if no active ride
  Future<ApiResponse<Map<String, dynamic>>> getActiveRide() async {
    return await _driverService.getActiveRide();
  }

  // ===========================================================================
  // 15. SCHEDULED RIDES
  // ===========================================================================

  /// Get driver's accepted scheduled rides
  /// [status] - Filter: 'upcoming', 'completed', 'cancelled', 'all'
  Future<ApiResponse<Map<String, dynamic>>> getScheduledRides({
    int page = 1,
    int limit = 20,
    String status = 'upcoming',
  }) async {
    return await _driverService.getScheduledRides(
      page: page,
      limit: limit,
      status: status,
    );
  }

  // ===========================================================================
  // 16. DRIVER RIDE HISTORY
  // ===========================================================================

  /// Get driver ride history
  /// [status] - Filter: 'completed', 'cancelled', 'all'
  Future<ApiResponse<Map<String, dynamic>>> getDriverRideHistory({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _driverService.getDriverRideHistory(
      page: page,
      limit: limit,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ===========================================================================
  // 17. DELIVERY-SPECIFIC OPERATIONS
  // ===========================================================================

  /// Driver confirms package pickup from the sender.
  /// Delivery status changes to `in_progress`.
  /// [packagePhotoUrl] - Optional photo proof of package pickup.
  Future<ApiResponse<Map<String, dynamic>>> pickupPackage(
    String rideId, {
    String? packagePhotoUrl,
  }) async {
    return await _driverService.pickupPackage(
      rideId,
      packagePhotoUrl: packagePhotoUrl,
    );
  }

  /// Driver delivers the package to the recipient.
  /// Requires the 6-digit delivery code collected from the recipient.
  /// Delivery status changes to `completed`.
  /// [code] - 6-digit delivery code (required).
  /// [receivedBy] - Name of the person who received the package.
  /// [photoUrl] - Photo proof of delivery.
  /// [signatureUrl] - Signature image URL.
  /// [notes] - Delivery notes.
  Future<ApiResponse<Map<String, dynamic>>> deliverPackage(
    String rideId, {
    required String code,
    String? receivedBy,
    String? photoUrl,
    String? signatureUrl,
    String? notes,
  }) async {
    return await _driverService.deliverPackage(
      rideId,
      code: code,
      receivedBy: receivedBy,
      photoUrl: photoUrl,
      signatureUrl: signatureUrl,
      notes: notes,
    );
  }
}
