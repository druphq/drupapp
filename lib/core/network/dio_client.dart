import 'package:dio/dio.dart';
import 'package:drup/router/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:drup/core/cache/cache_manager.dart';
import 'package:drup/router/app_router.dart';
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

    // 1. Error interceptor - Added first, runs LAST for errors (for final error transformation)
    _dio.interceptors.add(ErrorInterceptor());

    // 2. Connectivity check - fails fast if no network
    _dio.interceptors.add(ConnectivityInterceptor());

    // 3. Auth interceptor - adds authentication token
    _dio.interceptors.add(AuthInterceptor(cacheManager: _cacheManager));

    // 4. Cache interceptor - for offline support
    // _dio.interceptors.add(CacheInterceptor(cacheManager: _cacheManager));

    // 5. Pretty logger - only in debug mode
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

    // 6. Retry interceptor - retries failed requests (but not 401s)
    _dio.interceptors.add(RetryInterceptor(dio: _dio));

    // 7. Refresh token interceptor - Added last, runs FIRST for errors (handles 401 before transformation)
    _dio.interceptors.add(
      RefreshTokenInterceptor(
        dio: _dio,
        baseUrl: baseUrl,
        cacheManager: _cacheManager,
        onTokenExpired: _handleTokenExpired,
      ),
    );
  }

  /// Handle when refresh token expires
  void _handleTokenExpired() {
    debugPrint('Token expired - user needs to re-authenticate');
    final context = rootNavigator.currentContext;
    if (context != null && context.mounted) {
      context.go(AppRoutes.loginRoute);
    }
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
