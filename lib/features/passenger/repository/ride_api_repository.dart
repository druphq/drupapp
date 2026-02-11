import 'package:drup/data/api/api_routes.dart';
import 'package:drup/data/api/api_service.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';

/// Repository handling all ride-related API operations
class RideApiRepository {
  final ApiService _apiService;

  RideApiRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // ===========================================================================
  // FARE ESTIMATES
  // ===========================================================================

  /// Get fare estimates for all vehicle types
  /// Called when user confirms destination
  Future<ApiResponse<FareEstimateResponse>> getFareEstimates(
    FareEstimateRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.fareEstimate,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: FareEstimateResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get fare estimates',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // AVAILABLE SLOTS
  // ===========================================================================

  /// Get available time slots for shared rides on a specific date
  Future<ApiResponse<AvailableSlotsResponse>> getAvailableSlots(
    AvailableSlotsRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.availableSlots,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: AvailableSlotsResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get available slots',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // BOOK RIDE
  // ===========================================================================

  /// Book a ride
  /// Ride is created with status "pending" until payment is completed
  Future<ApiResponse<BookRideResponse>> bookRide(
    BookRideRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.bookRide,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: BookRideResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to book ride',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // PAYMENT
  // ===========================================================================

  /// Initialize ride payment
  Future<ApiResponse<InitPaymentResponse>> initializePayment(
    InitPaymentRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.initRidePayment,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: InitPaymentResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to initialize payment',
      statusCode: response.statusCode,
    );
  }

  /// Pay with saved card
  Future<ApiResponse<InitPaymentResponse>> payWithSavedCard(
    PayWithSavedCardRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.payWithSavedCard,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: InitPaymentResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to process payment',
      statusCode: response.statusCode,
    );
  }

  /// Verify payment status
  Future<ApiResponse<VerifyPaymentResponse>> verifyPayment(
    String reference,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.verifyPayment(reference),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: VerifyPaymentResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to verify payment',
      statusCode: response.statusCode,
    );
  }

  /// Get saved cards
  Future<ApiResponse<SavedCardsResponse>> getSavedCards() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.savedCards,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: SavedCardsResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get saved cards',
      statusCode: response.statusCode,
    );
  }

  /// Delete saved card
  Future<ApiResponse<void>> deleteSavedCard(String cardId) async {
    final response = await _apiService.delete(ApiRoutes.deleteCard(cardId));

    return ApiResponse(
      success: response.success,
      message: response.message ?? 'Card deleted successfully',
      statusCode: response.statusCode,
    );
  }

  /// Set default card
  Future<ApiResponse<void>> setDefaultCard(String cardId) async {
    final response = await _apiService.put(ApiRoutes.setDefaultCard(cardId));

    return ApiResponse(
      success: response.success,
      message: response.message ?? 'Default card set successfully',
      statusCode: response.statusCode,
    );
  }

  /// Get wallet balance
  Future<ApiResponse<WalletBalanceResponse>> getWalletBalance() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.walletBalance,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: WalletBalanceResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get wallet balance',
      statusCode: response.statusCode,
    );
  }

  /// Top up wallet
  Future<ApiResponse<WalletTopUpResponse>> topUpWallet(
    WalletTopUpRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.walletTopUp,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: WalletTopUpResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to top up wallet',
      statusCode: response.statusCode,
    );
  }

  /// Get wallet transactions
  Future<ApiResponse<WalletTransactionsResponse>> getWalletTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.walletTransactions,
      queryParameters: {'page': page, 'limit': limit},
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: WalletTransactionsResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get wallet transactions',
      statusCode: response.statusCode,
    );
  }

  /// Get payment history
  Future<ApiResponse<PaymentHistoryResponse>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    String? status,
    String? paymentType,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) queryParams['status'] = status;
    if (paymentType != null) queryParams['paymentType'] = paymentType;

    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.paymentHistory,
      queryParameters: queryParams,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: PaymentHistoryResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get payment history',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // ACTIVE RIDE & RIDE DETAILS
  // ===========================================================================

  /// Get active ride
  Future<ApiResponse<ActiveRideResponse>> getActiveRide() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.activeRide,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: ActiveRideResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get active ride',
      statusCode: response.statusCode,
    );
  }

  /// Get ride by ID
  Future<ApiResponse<BookedRide>> getRideById(String rideId) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.ride(rideId),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final rideData = data['ride'] as Map<String, dynamic>?;
        if (rideData != null) {
          return ApiResponse.success(
            data: BookedRide.fromJson(rideData),
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get ride details',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // RIDE HISTORY
  // ===========================================================================

  /// Get ride history
  Future<ApiResponse<RideHistoryResponse>> getRideHistory({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status != 'all') queryParams['status'] = status;
    if (startDate != null)
      queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final response = await _apiService.get<Map<String, dynamic>>(
      ApiRoutes.rideHistory,
      queryParameters: queryParams,
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: RideHistoryResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to get ride history',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // CANCEL RIDE
  // ===========================================================================

  /// Cancel a ride
  Future<ApiResponse<CancelRideResponse>> cancelRide(
    String rideId,
    CancelRideRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.cancelRide(rideId),
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: CancelRideResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to cancel ride',
      statusCode: response.statusCode,
    );
  }

  // ===========================================================================
  // RATE RIDE
  // ===========================================================================

  /// Rate a completed ride
  Future<ApiResponse<RateRideResponse>> rateRide(
    String rideId,
    RateRideRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.rateRide(rideId),
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: RateRideResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to rate ride',
      statusCode: response.statusCode,
    );
  }
}
