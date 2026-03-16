import 'package:flutter/foundation.dart';
import '../api/api_routes.dart';
import '../api/api_service.dart';

/// Service handling all delivery-related API calls
class DeliveryService {
  final ApiService _apiService;

  DeliveryService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // ===========================================================================
  // 1. FARE ESTIMATE
  // ===========================================================================

  /// Get a delivery fare estimate before booking.
  Future<ApiResponse<Map<String, dynamic>>> getDeliveryEstimate(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.deliveryEstimate,
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
        message: response.message ?? 'Failed to get delivery estimate',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error getting delivery estimate: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 2. BOOK DELIVERY
  // ===========================================================================

  /// Book a delivery after getting a fare estimate.
  /// The delivery is created with status `booked` until payment is confirmed.
  Future<ApiResponse<Map<String, dynamic>>> bookDelivery(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiRoutes.bookDelivery,
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
        message: response.message ?? 'Failed to book delivery',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error booking delivery: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  // ===========================================================================
  // 3. GET DELIVERY BY ID
  // ===========================================================================

  /// Fetch a single delivery by its ride ID.
  /// Deliveries share the `/rides/:id` endpoint.
  Future<ApiResponse<Map<String, dynamic>>> getDeliveryById(
    String deliveryId,
  ) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiRoutes.ride(deliveryId),
      );

      if (response.success && response.data != null) {
        final responseData = response.data!['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          final rideData = responseData['ride'] as Map<String, dynamic>?;
          if (rideData != null) {
            return ApiResponse.success(
              data: rideData,
              message: response.message,
              statusCode: response.statusCode,
            );
          }
        }
      }

      return ApiResponse.failure(
        message: response.message ?? 'Failed to get delivery details',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Error getting delivery by ID: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }
}
