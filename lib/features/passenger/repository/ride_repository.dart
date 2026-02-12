import 'package:drup/data/api/api_routes.dart';
import 'package:drup/data/api/api_service.dart';
import 'package:drup/features/passenger/model/ride_api_models.dart';
import '../model/ride.dart';
import '../../drivers/model/ride_request.dart';
import '../../drivers/model/driver.dart';
import '../model/location_model.dart';
import '../../../data/services/ride_service.dart';
import '../../../core/constants/constants.dart';

/// Repository handling all ride-related operations (local and API)
class RideRepository {
  final RideService _rideService;
  final ApiService _apiService;

  RideRepository(this._rideService, {ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // ===========================================================================
  // LOCAL RIDE OPERATIONS (via RideService)
  // ===========================================================================

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

  /// Cancel ride locally (complete the ride)
  Future<bool> cancelRideLocal(String rideId) async {
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

  // ===========================================================================
  // FARE ESTIMATES (API)
  // ===========================================================================

  /// Get fare estimates for all vehicle types
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
  // AVAILABLE SLOTS (API)
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
  // BOOK RIDE (API)
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
  // PAYMENT (API)
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

  // ===========================================================================
  // WALLET (API)
  // ===========================================================================

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
  // ACTIVE RIDE & RIDE DETAILS (API)
  // ===========================================================================

  /// Get active ride from API
  Future<ApiResponse<ActiveRideResponse>> getActiveRideFromApi() async {
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
  // RIDE HISTORY (API)
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
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
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
  // CANCEL RIDE (API)
  // ===========================================================================

  /// Cancel a ride via API
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
  // RATE RIDE (API)
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
