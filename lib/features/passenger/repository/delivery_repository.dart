import 'package:drup/data/api/api_service.dart';
import 'package:drup/data/services/delivery_service.dart';
import 'package:drup/features/passenger/model/delivery_api_models.dart';

/// Repository handling all delivery-related operations
/// Acts as the single source of truth for delivery data in the app
class DeliveryRepository {
  final DeliveryService _deliveryService;

  DeliveryRepository({DeliveryService? deliveryService})
    : _deliveryService = deliveryService ?? DeliveryService();

  // ===========================================================================
  // FARE ESTIMATE (API)
  // ===========================================================================

  /// Get a delivery fare estimate before booking.
  ///
  /// [request] contains pickup, dropoff, vehicleType and optional packageSize.
  Future<ApiResponse<DeliveryEstimateResponse>> getDeliveryEstimate(
    DeliveryEstimateRequest request,
  ) async {
    final response = await _deliveryService.getDeliveryEstimate(
      request.toJson(),
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(
        data: DeliveryEstimateResponse.fromJson(response.data!),
        message: response.message,
        statusCode: response.statusCode,
      );
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
    final response = await _deliveryService.bookDelivery(request.toJson());

    if (response.success && response.data != null) {
      return ApiResponse.success(
        data: BookDeliveryResponse.fromJson(response.data!),
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to book delivery',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // GET DELIVERY BY ID (API)
  // ===========================================================================

  /// Fetch full delivery details by ID.
  Future<ApiResponse<BookedDelivery>> getDeliveryById(String deliveryId) async {
    final response = await _deliveryService.getDeliveryById(deliveryId);

    if (response.success && response.data != null) {
      return ApiResponse.success(
        data: BookedDelivery.fromJson(response.data!),
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get delivery details',
      statusCode: response.statusCode,
    );
  }
}
