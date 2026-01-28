import 'package:dio/dio.dart';
import 'package:drup/core/cache/cache_manager.dart';

/// Interceptor that adds authentication token to requests
class AuthInterceptor extends Interceptor {
  final CacheManager _cacheManager;

  /// Storage keys for tokens
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  AuthInterceptor({CacheManager? cacheManager})
    : _cacheManager = cacheManager ?? CacheManager.instance;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    if (_isPublicEndpoint(options.path)) {
      return handler.next(options);
    }

    // Get token from cache
    final token = await _cacheManager.getPref(accessTokenKey);

    if (token != null && token is String && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  /// Check if the endpoint is public and doesn't need authentication
  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/send-otp',
      '/auth/verify-otp',
      '/auth/forgot-password',
      '/auth/refresh-token',
    ];

    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }
}
