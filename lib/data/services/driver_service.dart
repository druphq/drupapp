import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drup/features/auth/model/auth.dart';
import 'package:flutter/foundation.dart';
import '../api/api_routes.dart';
import '../api/api_service.dart';

/// Service handling all driver-related API calls
class DriverService {
  final ApiService _apiService;

  DriverService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

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
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;
      if (vehicle != null) data['vehicle'] = vehicle;

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.applyDriver,
        data: data,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to submit driver application',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error applying as driver: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Check driver application status
  Future<ApiResponse<Map<String, dynamic>>> getDriverApplicationStatus() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverStatus,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch driver status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching driver application status: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 2. SWITCH ROLE (User ↔ Driver)
  // ===========================================================================

  /// Switch between user and driver modes
  /// Returns new tokens and optionally driverProfile when switching to driver
  Future<ApiResponse<SwitchRoleResponse>> switchRole(String role) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.switchRole,
        data: {'role': role},
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: SwitchRoleResponse.fromJson(responseData),
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to switch role',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error switching role: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 3. DRIVER PROFILE
  // ===========================================================================

  /// Get driver profile
  Future<ApiResponse<Map<String, dynamic>>> getDriverProfile() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverProfile,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch driver profile',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching driver profile: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update driver profile
  Future<ApiResponse<Map<String, dynamic>>> updateDriverProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (email != null) data['email'] = email;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;

      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.driverProfile,
        data: data,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update driver profile',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating driver profile: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Upload driver profile photo
  Future<ApiResponse<Map<String, dynamic>>> uploadDriverProfilePhoto(
    File photoFile,
  ) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoFile.path),
      });

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.driverProfilePhoto,
        data: formData,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to upload profile photo',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error uploading driver profile photo: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update driver device token for push notifications
  Future<ApiResponse<void>> updateDriverDeviceToken(
    String deviceToken,
    String deviceType,
  ) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.driverDeviceToken,
        data: {'deviceToken': deviceToken, 'deviceType': deviceType},
      );

      return response.success
          ? ApiResponse.success(message: response.message)
          : ApiResponse.failure(
              message: response.message ?? 'Failed to update device token',
              statusCode: response.statusCode,
            );
    } catch (e) {
      debugPrint('Error updating driver device token: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 4. VEHICLE MANAGEMENT
  // ===========================================================================

  /// Get vehicle info
  Future<ApiResponse<Map<String, dynamic>>> getVehicleInfo() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverVehicle,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch vehicle info',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching vehicle info: $e');
      return ApiResponse.failure(message: e.toString());
    }
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
    try {
      final data = <String, dynamic>{};
      if (type != null) data['type'] = type;
      if (make != null) data['make'] = make;
      if (model != null) data['model'] = model;
      if (year != null) data['year'] = year;
      if (color != null) data['color'] = color;
      if (licensePlate != null) data['licensePlate'] = licensePlate;

      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.driverVehicle,
        data: data,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update vehicle info',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating vehicle info: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 5. DOCUMENT MANAGEMENT
  // ===========================================================================

  /// Get all driver documents with verification status
  Future<ApiResponse<Map<String, dynamic>>> getDocuments() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverDocuments,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch documents',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Upload a document
  /// [documentFile] - The document file (PDF, JPEG, PNG)
  /// [type] - Document type enum: profile_photo, drivers_license,
  ///          vehicle_photo_external, vehicle_photo_internal,
  ///          vehicle_registration, insurance, national_id,
  ///          vehicle_inspection
  /// [expiryDate] - Optional ISO 8601 expiry date
  Future<ApiResponse<Map<String, dynamic>>> uploadDocument({
    required File documentFile,
    required String type,
    String? expiryDate,
  }) async {
    try {
      final formMap = <String, dynamic>{
        'document': await MultipartFile.fromFile(documentFile.path),
        'type': type,
      };
      if (expiryDate != null) formMap['expiryDate'] = expiryDate;

      final formData = FormData.fromMap(formMap);

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.driverDocuments,
        data: formData,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to upload document',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error uploading document: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 6. VERIFICATION STATUS
  // ===========================================================================

  /// Get driver verification status
  Future<ApiResponse<Map<String, dynamic>>> getVerificationStatus() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverVerificationStatus,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch verification status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching verification status: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 7. GO ONLINE / OFFLINE
  // ===========================================================================

  /// Toggle driver online/offline status
  Future<ApiResponse<Map<String, dynamic>>> updateOnlineStatus(
    bool isOnline,
  ) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.driverOnlineStatus,
        data: {'isOnline': isOnline},
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update online status',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating online status: $e');
      return ApiResponse.failure(message: e.toString());
    }
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
    try {
      final data = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (heading != null) data['heading'] = heading;
      if (speed != null) data['speed'] = speed;

      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.driverLocation,
        data: data,
      );

      return response.success
          ? ApiResponse.success(
              message: response.message,
              statusCode: response.statusCode,
            )
          : ApiResponse.failure(
              message: response.message ?? 'Failed to update location',
              statusCode: response.statusCode,
            );
    } catch (e) {
      debugPrint('Error updating driver location: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 9. NEARBY RIDE REQUESTS
  // ===========================================================================

  /// Get ride requests near the driver's current location
  Future<ApiResponse<Map<String, dynamic>>> getNearbyRides({
    required double latitude,
    required double longitude,
    int? radius,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (radius != null) queryParams['radius'] = radius;

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.nearbyRides,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch nearby rides',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching nearby rides: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 10. ACCEPT / DECLINE RIDE
  // ===========================================================================

  /// Accept a ride request (works for both on-demand and scheduled rides)
  /// Atomic first-accept-wins for scheduled rides
  Future<ApiResponse<Map<String, dynamic>>> acceptRide(String rideId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.acceptRide(rideId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to accept ride',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error accepting ride: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Decline a ride request
  Future<ApiResponse<void>> declineRide(String rideId, {String? reason}) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null) data['reason'] = reason;

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.declineRide(rideId),
        data: data,
      );

      return response.success
          ? ApiResponse.success(
              message: response.message,
              statusCode: response.statusCode,
            )
          : ApiResponse.failure(
              message: response.message ?? 'Failed to decline ride',
              statusCode: response.statusCode,
            );
    } catch (e) {
      debugPrint('Error declining ride: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 11. RIDE LIFECYCLE — INDIVIDUAL RIDES
  // ===========================================================================

  /// Mark arrival at pickup location (individual rides only)
  Future<ApiResponse<Map<String, dynamic>>> arrivedAtPickup(
    String rideId,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.arrivedAtPickup(rideId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to confirm arrival',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error marking arrival at pickup: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Start ride (passenger in car, ride begins)
  /// For shared rides: call after all passengers are picked up
  Future<ApiResponse<Map<String, dynamic>>> startRide(
    String rideId, {
    String? otp,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (otp != null) data['otp'] = otp;

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.startRide(rideId),
        data: data,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to start ride',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error starting ride: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Complete ride (reached destination)
  /// For shared rides: call after all passengers are dropped off
  Future<ApiResponse<Map<String, dynamic>>> completeRide(String rideId) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.completeRide(rideId),
        data: <String, dynamic>{},
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to complete ride',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error completing ride: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 12. SHARED RIDE PASSENGER MANAGEMENT
  // ===========================================================================

  /// Get list of passengers in a shared ride
  Future<ApiResponse<Map<String, dynamic>>> getPassengers(String rideId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.ridePassengers(rideId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch passengers',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching passengers: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Mark arrival at a specific passenger's pickup location
  Future<ApiResponse<Map<String, dynamic>>> arrivedAtPassengerPickup(
    String rideId,
    String passengerId,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.passengerArrived(rideId, passengerId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message:
            response.message ?? 'Failed to confirm arrival at passenger pickup',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error marking arrival at passenger pickup: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Pick up a specific passenger
  Future<ApiResponse<Map<String, dynamic>>> pickUpPassenger(
    String rideId,
    String passengerId,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.passengerPickedUp(rideId, passengerId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to pick up passenger',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error picking up passenger: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Mark a passenger as no-show
  Future<ApiResponse<Map<String, dynamic>>> markPassengerNoShow(
    String rideId,
    String passengerId,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.passengerNoShow(rideId, passengerId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to mark passenger as no-show',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error marking passenger no-show: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Mark arrival at a specific passenger's dropoff location
  /// Ride must be `in_progress`
  Future<ApiResponse<Map<String, dynamic>>> arrivedAtPassengerDropoff(
    String rideId,
    String passengerId,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.passengerArrivingDropoff(rideId, passengerId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message:
            response.message ??
            'Failed to confirm arrival at passenger dropoff',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error marking arrival at passenger dropoff: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Drop off a specific passenger at their destination
  Future<ApiResponse<Map<String, dynamic>>> dropOffPassenger(
    String rideId,
    String passengerId,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.passengerDroppedOff(rideId, passengerId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to drop off passenger',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error dropping off passenger: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 13. CANCEL RIDE (DRIVER)
  // ===========================================================================

  /// Cancel a ride as driver
  /// Ride goes back to `confirmed` for re-assignment
  Future<ApiResponse<Map<String, dynamic>>> cancelRide(
    String rideId, {
    required String reason,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.driverCancelRide(rideId),
        data: {'reason': reason},
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to cancel ride',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error cancelling ride: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 14. DRIVER ACTIVE RIDE
  // ===========================================================================

  /// Check if the driver has a current active ride
  Future<ApiResponse<Map<String, dynamic>>> getActiveRide() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverActiveRide,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch active ride',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching active ride: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 15. SCHEDULED RIDES
  // ===========================================================================

  /// Get driver's accepted scheduled rides
  /// Powers the "Upcoming" section on the driver home screen
  Future<ApiResponse<Map<String, dynamic>>> getScheduledRides({
    int page = 1,
    int limit = 20,
    String status = 'upcoming',
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverScheduledRides,
        queryParameters: {'page': page, 'limit': limit, 'status': status},
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch scheduled rides',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching scheduled rides: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 16. DRIVER RIDE HISTORY
  // ===========================================================================

  /// Get driver ride history
  Future<ApiResponse<Map<String, dynamic>>> getDriverRideHistory({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status != 'all') queryParams['status'] = status;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverRideHistory,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch ride history',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching driver ride history: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 17. DELIVERY-SPECIFIC OPERATIONS
  // ===========================================================================

  /// Driver picks up the package from the sender.
  /// [packagePhotoUrl] - Optional photo proof of package pickup.
  Future<ApiResponse<Map<String, dynamic>>> pickupPackage(
    String rideId, {
    String? packagePhotoUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (packagePhotoUrl != null) data['packagePhotoUrl'] = packagePhotoUrl;

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.pickupPackage(rideId),
        data: data,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to confirm package pickup',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error picking up package: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Driver delivers the package to the recipient.
  /// [code] - 6-digit delivery code (required, collected from recipient).
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
    try {
      final data = <String, dynamic>{'code': code};
      if (receivedBy != null) data['receivedBy'] = receivedBy;
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (signatureUrl != null) data['signatureUrl'] = signatureUrl;
      if (notes != null) data['notes'] = notes;

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.deliverPackage(rideId),
        data: data,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to complete delivery',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error delivering package: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 18. EARNINGS
  // ===========================================================================

  /// Get driver earnings summary
  /// Optional date range filter via [startDate] and [endDate]
  Future<ApiResponse<Map<String, dynamic>>> getEarnings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverEarnings,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch earnings',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 19. BANK ACCOUNT
  // ===========================================================================

  /// Get driver bank account details
  Future<ApiResponse<Map<String, dynamic>>> getBankAccount() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.driverBankAccount,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          final bankAccount =
              responseData['bankAccount'] as Map<String, dynamic>?;
          if (bankAccount != null) {
            return ApiResponse.success(
              data: bankAccount,
              message: response.message,
              statusCode: response.statusCode,
            );
          }
          // bankAccount is null — no account saved yet
          return ApiResponse.success(
            data: null,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch bank account',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching bank account: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Update driver bank account
  Future<ApiResponse<Map<String, dynamic>>> updateBankAccount({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final response = await _apiService.patch<Map<String, dynamic>>(
        ApiRoutes.driverBankAccount,
        data: {
          'bankName': bankName,
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'accountName': accountName,
        },
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to update bank account',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error updating bank account: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Get list of supported banks
  Future<ApiResponse<List<dynamic>>> getBankList() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.bankList,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        final banks = data is List
            ? data
            : (data as Map<String, dynamic>?)?['banks'] as List? ?? [];
        return ApiResponse.success(
          data: banks,
          message: response.message,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to fetch bank list',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error fetching bank list: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Verify bank account before saving
  Future<ApiResponse<Map<String, dynamic>>> verifyBankAccount({
    required String bankCode,
    required String accountNumber,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.verifyBankAccount,
        data: {'bankCode': bankCode, 'accountNumber': accountNumber},
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ApiResponse.success(
            data: responseData,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to verify bank account',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error verifying bank account: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // DELETE ACCOUNT
  // ===========================================================================

  /// Delete driver account (permanent)
  Future<ApiResponse<void>> deleteAccount({String? reason}) async {
    try {
      final response = await _apiService.delete<Map<String, dynamic>>(
        ApiRoutes.deleteDriverAccount,
        data: reason != null ? {'reason': reason} : null,
      );

      if (response.success) {
        return ApiResponse.success(message: response.message);
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to delete account',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error deleting driver account: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }
}
