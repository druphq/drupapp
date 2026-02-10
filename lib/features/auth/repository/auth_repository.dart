import 'package:drup/core/cache/cache_manager.dart';
import 'package:drup/data/api/api_routes.dart';
import 'package:drup/features/auth/model/auth.dart';
import 'package:drup/data/models/user.dart';
import 'package:drup/data/api/api_service.dart';
import 'package:flutter/foundation.dart';

/// Repository handling all authentication operations
class AuthRepository {
  final ApiService _apiService;
  final CacheManager _cacheManager;

  /// Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'current_user';

  AuthRepository({ApiService? apiService, CacheManager? cacheManager})
    : _apiService = apiService ?? ApiService(),
      _cacheManager = cacheManager ?? CacheManager.instance;

  /// Request OTP for phone sign-in
  Future<ApiResponse<SignInResponse>> signIn(SignInRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.signIn,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: SignInResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to send OTP',
      statusCode: response.statusCode,
    );
  }

  /// Verify OTP and get auth tokens
  Future<ApiResponse<VerifyOtpResponse>> verifyOtp(
    VerifyOtpRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.verifyOtp,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final verifyResponse = VerifyOtpResponse.fromJson(data);

        // Store tokens and user
        await _storeAuthData(
          accessToken: verifyResponse.token,
          refreshToken: verifyResponse.refreshToken,
          user: verifyResponse.user,
        );

        return ApiResponse.success(
          data: verifyResponse,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to verify OTP',
      statusCode: response.statusCode,
    );
  }

  /// Authenticates Google account. Phone verification still required.
  Future<ApiResponse<GoogleSignInResponse>> googleSignIn(
    GoogleSignInRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.googleSignIn,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        return ApiResponse.success(
          data: GoogleSignInResponse.fromJson(data),
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Google sign-in failed',
      statusCode: response.statusCode,
    );
  }

  /// Call after Google Step 1 + Phone OTP verification.
  Future<ApiResponse<GoogleCompleteResponse>> googleComplete(
    GoogleCompleteRequest request,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.googleComplete,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final completeResponse = GoogleCompleteResponse.fromJson(data);

        // Store tokens and user
        await _storeAuthData(
          accessToken: completeResponse.token,
          refreshToken: completeResponse.refreshToken,
          user: completeResponse.user,
        );

        return ApiResponse.success(
          data: completeResponse,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Google sign-in completion failed',
      statusCode: response.statusCode,
    );
  }

  /// Used when access token expires.
  Future<ApiResponse<RefreshTokenResponse>> refreshToken() async {
    final storedRefreshToken = await _cacheManager.getPref(refreshTokenKey);

    if (storedRefreshToken == null) {
      return ApiResponse.failure(
        message: 'No refresh token available',
        statusCode: 401,
      );
    }

    final request = RefreshTokenRequest(
      refreshToken: storedRefreshToken.toString(),
    );

    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.refreshToken,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final refreshResponse = RefreshTokenResponse.fromJson(data);

        // Store new tokens
        await _cacheManager.storePref(accessTokenKey, refreshResponse.token);
        await _cacheManager.storePref(
          refreshTokenKey,
          refreshResponse.refreshToken,
        );

        return ApiResponse.success(
          data: refreshResponse,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to refresh token',
      statusCode: response.statusCode,
    );
  }

  /// Logout and invalidate refresh token
  Future<ApiResponse<void>> logout() async {
    final storedRefreshToken = await _cacheManager.getPref(refreshTokenKey);

    if (storedRefreshToken != null) {
      final request = LogoutRequest(
        refreshToken: storedRefreshToken.toString(),
      );

      await _apiService.post(ApiRoutes.logout, data: request.toJson());
    }

    // Clear local auth data
    await _clearAuthData();

    return ApiResponse.success(message: 'Logged out successfully');
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile(User user) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      ApiRoutes.updateProfile,
      data: {
        'firstName': user.firstName,
        'lastName': user.lastName,
        if (user.email != null) 'email': user.email,
        if (user.phone != null) 'phone': user.phone,
      },
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final updatedUser = User.fromJson(userData);
          // Update cached user
          await updateCachedUser(updatedUser);

          return ApiResponse.success(
            data: updatedUser,
            message: response.message,
            statusCode: response.statusCode,
          );
        }
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to update profile',
      statusCode: response.statusCode,
    );
  }

  /// Resend email verification OTP
  Future<ApiResponse<void>> resendEmailVerification() async {
    final response = await _apiService.post(ApiRoutes.resendEmailVerification);

    return ApiResponse(
      success: response.success,
      message: response.message ?? 'Email verification sent',
      statusCode: response.statusCode,
    );
  }

  /// Verify email with OTP
  Future<ApiResponse<User>> verifyEmail(VerifyEmailRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiRoutes.verifyEmail,
      data: request.toJson(),
    );

    if (response.success && response.data != null) {
      final data = response.data!['data'] as Map<String, dynamic>?;
      final userData = data?['user'] as Map<String, dynamic>?;
      if (userData != null) {
        final user = User.fromJson(userData);
        // Update cached user with verified email status
        await updateCachedUser(user);

        return ApiResponse.success(
          data: user,
          message: response.message,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse.failure(
      message: response.message ?? 'Failed to verify email',
      statusCode: response.statusCode,
    );
  }

  /// Store authentication data locally

  Future<void> _storeAuthData({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) async {
    await _cacheManager.storePref(accessTokenKey, accessToken);
    await _cacheManager.storePref(refreshTokenKey, refreshToken);
    await _cacheManager.storeObject(userKey, user.toJson());

    debugPrint('Auth data stored successfully');
  }

  /// Clear authentication data
  Future<void> _clearAuthData() async {
    await _cacheManager.clearPref(accessTokenKey);
    await _cacheManager.clearPref(refreshTokenKey);
    await _cacheManager.clearPref(userKey);

    debugPrint('Auth data cleared');
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    final token = await _cacheManager.getPref(accessTokenKey);
    return token?.toString();
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    final token = await _cacheManager.getPref(refreshTokenKey);
    return token?.toString();
  }

  /// Get current user from cache
  Future<User?> getCurrentUser() async {
    final userData = await _cacheManager.getObject(userKey);
    if (userData != null) {
      try {
        return User.fromJson(userData);
      } catch (e) {
        debugPrint('Error parsing cached user: $e');
        return null;
      }
    }
    return null;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Update cached user
  Future<void> updateCachedUser(User user) async {
    await _cacheManager.storeObject(userKey, user.toJson());
  }
}
