import 'package:drup/data/api/api_routes.dart';
import 'package:drup/data/api/api_service.dart';
import 'package:drup/features/passenger/model/delivery_api_models.dart';

/// Repository handling all delivery-related API operations
class DeliveryRepository {
  final ApiService _apiService;

  DeliveryRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // ===========================================================================
  // FARE ESTIMATE (API)
  // ===========================================================================

  /// Get a delivery fare estimate before booking.
  ///
  /// [request] contains pickup, dropoff, vehicleType and optional packageSize.
  Future<ApiResponse<DeliveryEstimateResponse>> getDeliveryEstimate(
    DeliveryEstimateRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.deliveryEstimate,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: DeliveryEstimateResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get delivery estimate',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // BOOK DELIVERY (API)
  // ===========================================================================

  /// Book a delivery after getting a fare estimate.
  ///
  /// The delivery is created with status `booked` until payment is confirmed.
  Future<ApiResponse<BookDeliveryResponse>> bookDelivery(
    BookDeliveryRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.bookDelivery,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: BookDeliveryResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to book delivery',
      statusCode: response.statusCode,
    );
  }
}
