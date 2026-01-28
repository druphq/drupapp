import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:drup/core/cache/cache_manager.dart';

/// Interceptor that handles token refresh when receiving 401 responses
class RefreshTokenInterceptor extends Interceptor {
  final Dio _dio;
  final CacheManager _cacheManager;
  final String _baseUrl;
  final VoidCallback? onTokenExpired;

  /// Storage keys for tokens
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  /// Flag to prevent multiple refresh attempts
  bool _isRefreshing = false;

  /// Queue of requests waiting for token refresh
  final List<_RequestRetryInfo> _pendingRequests = [];

  RefreshTokenInterceptor({
    required Dio dio,
    required String baseUrl,
    CacheManager? cacheManager,
    this.onTokenExpired,
  }) : _dio = dio,
       _baseUrl = baseUrl,
       _cacheManager = cacheManager ?? CacheManager.instance;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 Unauthorized errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for login/refresh endpoints to prevent infinite loops
    if (_isAuthEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    // If already refreshing, queue this request
    if (_isRefreshing) {
      return _queueRequest(err, handler);
    }

    _isRefreshing = true;

    try {
      final newToken = await _refreshToken();

      if (newToken != null) {
        // Retry the original request with new token
        final response = await _retryRequest(err.requestOptions, newToken);
        handler.resolve(response);

        // Retry all pending requests
        _retryPendingRequests(newToken);
      } else {
        // Token refresh failed - user needs to re-authenticate
        _handleTokenExpired();
        handler.next(err);
        _rejectPendingRequests(err);
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      _handleTokenExpired();
      handler.next(err);
      _rejectPendingRequests(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refresh the access token using the refresh token
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _cacheManager.getPref(refreshTokenKey);

      if (refreshToken == null || refreshToken.toString().isEmpty) {
        debugPrint('No refresh token available');
        return null;
      }

      // Create a new Dio instance to avoid interceptor loops
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await refreshDio.post(
        '/auth/user/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'] as Map<String, dynamic>?;
        final newAccessToken = responseData?['token'] as String?;
        final newRefreshToken = responseData?['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _cacheManager.storePref(accessTokenKey, newAccessToken);

          if (newRefreshToken != null) {
            await _cacheManager.storePref(refreshTokenKey, newRefreshToken);
          }

          debugPrint('Token refreshed successfully');
          return newAccessToken;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return null;
    }
  }

  /// Retry a request with a new token
  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String newToken,
  ) async {
    final options = Options(
      method: requestOptions.method,
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $newToken'},
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Queue a request to be retried after token refresh
  void _queueRequest(DioException err, ErrorInterceptorHandler handler) {
    _pendingRequests.add(
      _RequestRetryInfo(requestOptions: err.requestOptions, handler: handler),
    );
  }

  /// Retry all pending requests with the new token
  void _retryPendingRequests(String newToken) async {
    for (final request in _pendingRequests) {
      try {
        final response = await _retryRequest(request.requestOptions, newToken);
        request.handler.resolve(response);
      } catch (e) {
        request.handler.reject(
          DioException(requestOptions: request.requestOptions, error: e),
        );
      }
    }
    _pendingRequests.clear();
  }

  /// Reject all pending requests
  void _rejectPendingRequests(DioException error) {
    for (final request in _pendingRequests) {
      request.handler.next(
        DioException(
          requestOptions: request.requestOptions,
          error: error.error,
          response: error.response,
          type: error.type,
        ),
      );
    }
    _pendingRequests.clear();
  }

  /// Handle token expiration
  void _handleTokenExpired() {
    _clearTokens();
    onTokenExpired?.call();
  }

  /// Clear stored tokens
  Future<void> _clearTokens() async {
    await _cacheManager.clearPref(accessTokenKey);
    await _cacheManager.clearPref(refreshTokenKey);
  }

  /// Check if the endpoint is an auth endpoint
  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/refresh-token') ||
        path.contains('/auth/login') ||
        path.contains('/auth/register');
  }
}

/// Helper class to store pending request info
class _RequestRetryInfo {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _RequestRetryInfo({required this.requestOptions, required this.handler});
}
