import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that automatically retries failed requests
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryableStatusCodes;

  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryableStatusCodes = const [408, 500, 502, 503, 504],
  }) : _dio = dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Get current retry count from request options
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    // Check if we should retry
    if (_shouldRetry(err, retryCount)) {
      debugPrint(
        'Retrying request (${retryCount + 1}/$maxRetries): ${err.requestOptions.path}',
      );

      await Future.delayed(_getRetryDelay(retryCount));

      try {
        // Clone request with updated retry count
        final options = err.requestOptions;
        options.extra['retryCount'] = retryCount + 1;

        final response = await _dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // If retry fails, pass to next handler
        if (e is DioException) {
          return onError(e, handler);
        }
        handler.next(err);
        return;
      }
    }

    handler.next(err);
  }

  /// Check if the request should be retried
  bool _shouldRetry(DioException error, int retryCount) {
    if (retryCount >= maxRetries) return false;

    // Don't retry cancelled requests
    if (error.type == DioExceptionType.cancel) return false;

    // Retry on connection errors
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // Retry on specific status codes
    final statusCode = error.response?.statusCode;
    if (statusCode != null && retryableStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  /// Get delay before retrying (exponential backoff)
  Duration _getRetryDelay(int retryCount) {
    // Exponential backoff: 1s, 2s, 4s, etc.
    return Duration(
      milliseconds: retryDelay.inMilliseconds * (1 << retryCount),
    );
  }
}
