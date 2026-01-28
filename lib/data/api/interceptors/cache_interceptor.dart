import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:drup/core/cache/cache_manager.dart';

/// Interceptor that caches GET requests for offline access
class CacheInterceptor extends Interceptor {
  final CacheManager _cacheManager;
  final Duration cacheDuration;

  /// Prefix for cache keys
  static const String _cachePrefix = 'api_cache_';

  CacheInterceptor({
    CacheManager? cacheManager,
    this.cacheDuration = const Duration(minutes: 30),
  }) : _cacheManager = cacheManager ?? CacheManager.instance;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only cache GET requests
    if (options.method != 'GET') {
      return handler.next(options);
    }

    // Skip if cache is explicitly disabled for this request
    if (options.extra['noCache'] == true) {
      return handler.next(options);
    }

    // Check if we should force refresh
    if (options.extra['forceRefresh'] == true) {
      return handler.next(options);
    }

    // Try to get cached response
    final cacheKey = _getCacheKey(options);
    final cachedData = await _getCachedResponse(cacheKey);

    if (cachedData != null) {
      debugPrint('Cache hit for: ${options.path}');
      handler.resolve(
        Response(
          requestOptions: options,
          data: cachedData['data'],
          statusCode: 200,
          extra: {'fromCache': true},
        ),
      );
      return;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Only cache successful GET requests
    if (response.requestOptions.method == 'GET' &&
        response.statusCode == 200 &&
        response.requestOptions.extra['noCache'] != true) {
      final cacheKey = _getCacheKey(response.requestOptions);
      await _cacheResponse(cacheKey, response.data);
    }

    handler.next(response);
  }

  /// Generate a unique cache key for the request
  String _getCacheKey(RequestOptions options) {
    final queryString = options.queryParameters.isNotEmpty
        ? '?${options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    return '$_cachePrefix${options.path}$queryString';
  }

  /// Get cached response if still valid
  Future<Map<String, dynamic>?> _getCachedResponse(String cacheKey) async {
    try {
      final cachedString = await _cacheManager.getPref(cacheKey);
      if (cachedString == null || cachedString is! String) return null;

      final cached = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cached['timestamp'] as int;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      ).add(cacheDuration);

      if (DateTime.now().isBefore(expiresAt)) {
        return cached;
      }

      // Cache expired, remove it
      await _cacheManager.clearPref(cacheKey);
      return null;
    } catch (e) {
      debugPrint('Error reading cache: $e');
      return null;
    }
  }

  /// Cache the response
  Future<void> _cacheResponse(String cacheKey, dynamic data) async {
    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await _cacheManager.storePref(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error caching response: $e');
    }
  }
}
