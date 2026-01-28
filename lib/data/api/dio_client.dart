import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:drup/core/cache/cache_manager.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
// import 'interceptors/cache_interceptor.dart';

/// Singleton Dio client with all interceptors configured
class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  final CacheManager _cacheManager;

  /// Private constructor
  DioClient._({CacheManager? cacheManager})
    : _cacheManager = cacheManager ?? CacheManager.instance {
    _dio = _createDio();
    _setupInterceptors();
  }

  /// Get singleton instance
  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  /// Get the Dio instance
  Dio get dio => _dio;

  /// Get base URL from environment
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  /// Create and configure Dio instance
  Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// Setup all interceptors in the correct order
  void _setupInterceptors() {
    // Clear any existing interceptors
    _dio.interceptors.clear();

    // 1. Connectivity check - runs first to fail fast if no network
    _dio.interceptors.add(ConnectivityInterceptor());

    // 2. Auth interceptor - adds authentication token
    _dio.interceptors.add(AuthInterceptor(cacheManager: _cacheManager));

    // 3. Cache interceptor - for offline support
    // _dio.interceptors.add(CacheInterceptor(cacheManager: _cacheManager));

    // 4. Pretty logger - only in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    // 5. Retry interceptor - retries failed requests
    _dio.interceptors.add(RetryInterceptor(dio: _dio));

    // 6. Refresh token interceptor - handles 401 and refreshes token
    _dio.interceptors.add(
      RefreshTokenInterceptor(
        dio: _dio,
        baseUrl: baseUrl,
        cacheManager: _cacheManager,
        onTokenExpired: _handleTokenExpired,
      ),
    );

    // 7. Error interceptor - transforms errors (runs last for error handling)
    _dio.interceptors.add(ErrorInterceptor());
  }

  /// Handle when refresh token expires
  void _handleTokenExpired() {
    debugPrint('Token expired - user needs to re-authenticate');
    // You can add navigation to login screen or emit an event here
    // Example: eventBus.emit(TokenExpiredEvent());
  }

  /// Reset the singleton instance (useful for testing or logout)
  static void reset() {
    _instance = null;
  }

  /// Create a new Dio instance with custom configuration
  static Dio createCustomDio({
    required String baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
    bool addLogger = true,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
      ),
    );

    if (addLogger && kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }

    return dio;
  }
}
