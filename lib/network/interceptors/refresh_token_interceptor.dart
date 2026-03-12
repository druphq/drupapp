import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drup/data/api/api_routes.dart';
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

  /// Completer to coordinate token refresh across multiple requests
  Completer<String?>? _refreshCompleter;

  RefreshTokenInterceptor({
    required Dio dio,
    required String baseUrl,
    CacheManager? cacheManager,
    this.onTokenExpired,
  }) : _dio = dio,
       _baseUrl = baseUrl,
       _cacheManager = cacheManager ?? CacheManager.instance;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Handle 401 in response interceptor since validateStatus treats it as success
    if (response.statusCode == 401) {
      debugPrint('🚨 401 Unauthorized detected in response');

      // Skip refresh for login/refresh endpoints to prevent infinite loops
      if (_isAuthEndpoint(response.requestOptions.path)) {
        return handler.next(response);
      }

      // If already refreshing, wait for it to complete
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        try {
          debugPrint('⏳ Waiting for ongoing token refresh...');
          final newToken = await _refreshCompleter!.future;
          if (newToken != null) {
            // Retry the original request with new token
            final retryResponse = await _retryRequest(
              response.requestOptions,
              newToken,
            );
            return handler.resolve(retryResponse);
          } else {
            return handler.next(response);
          }
        } catch (e) {
          return handler.next(response);
        }
      }

      // Start token refresh
      _refreshCompleter = Completer<String?>();

      try {
        debugPrint('🔄 Refreshing token due to 401 error...');
        final newToken = await _refreshToken();

        if (newToken != null) {
          debugPrint('✅ Token refreshed successfully, retrying request...');
          // Complete the completer for other waiting requests
          if (!_refreshCompleter!.isCompleted) {
            _refreshCompleter!.complete(newToken);
          }

          // Retry the original request with new token
          final retryResponse = await _retryRequest(
            response.requestOptions,
            newToken,
          );
          handler.resolve(retryResponse);
        } else {
          debugPrint('❌ Token refresh failed');
          // Complete the completer with null
          if (!_refreshCompleter!.isCompleted) {
            _refreshCompleter!.complete(null);
          }

          // Token refresh failed - user needs to re-authenticate
          _handleTokenExpired();
          handler.next(response);
        }
      } catch (e) {
        debugPrint('❌ Token refresh error: $e');

        // Complete the completer with error
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.completeError(e);
        }

        _handleTokenExpired();
        handler.next(response);
      } finally {
        // Reset the completer after a short delay
        Future.delayed(const Duration(milliseconds: 100), () {
          _refreshCompleter = null;
        });
      }
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint(
      '🔍 RefreshTokenInterceptor.onError called with status: ${err.response?.statusCode}',
    );

    // Only handle 401 Unauthorized errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip refresh for login/refresh endpoints to prevent infinite loops
    if (_isAuthEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    // If already refreshing, wait for it to complete
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      try {
        debugPrint('⏳ Waiting for ongoing token refresh...');
        final newToken = await _refreshCompleter!.future;
        if (newToken != null) {
          // Retry the original request with new token
          final response = await _retryRequest(err.requestOptions, newToken);
          return handler.resolve(response);
        } else {
          return handler.next(err);
        }
      } catch (e) {
        return handler.next(err);
      }
    }

    // Start token refresh
    _refreshCompleter = Completer<String?>();

    try {
      debugPrint('🔄 Refreshing token due to 401 error...');
      final newToken = await _refreshToken();

      if (newToken != null) {
        debugPrint('✅ Token refreshed successfully, retrying request...');
        // Complete the completer for other waiting requests
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(newToken);
        }

        // Retry the original request with new token
        final response = await _retryRequest(err.requestOptions, newToken);
        handler.resolve(response);
      } else {
        debugPrint('❌ Token refresh failed');
        // Complete the completer with null
        if (!_refreshCompleter!.isCompleted) {
          _refreshCompleter!.complete(null);
        }

        // Token refresh failed - user needs to re-authenticate
        _handleTokenExpired();
        handler.next(err);
      }
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');

      // Complete the completer with error
      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(e);
      }

      _handleTokenExpired();
      handler.next(err);
    } finally {
      // Reset the completer after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _refreshCompleter = null;
      });
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
        ApiRoutes.refreshToken,
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
    // Clone the request options and update the token
    final newOptions = requestOptions.copyWith(
      headers: {...requestOptions.headers, 'Authorization': 'Bearer $newToken'},
    );

    // Use fetch to bypass interceptors and prevent loops
    return _dio.fetch<dynamic>(newOptions);
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
    return path.contains(ApiRoutes.refreshToken) ||
        path.contains(ApiRoutes.refreshToken) ||
        path.contains(ApiRoutes.signIn);
  }
}
