import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_exceptions.dart';

/// Interceptor that handles and transforms errors into user-friendly exceptions
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _handleError(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
        message: exception.message,
      ),
    );
  }

  /// Transform DioException into ApiException
  ApiException _handleError(DioException error) {
    debugPrint('API Error: ${error.type} - ${error.message}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message:
              'Connection timed out. Please check your internet and try again.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'No internet connection. Please check your network.',
          statusCode: null,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Security certificate error. Please try again later.',
          statusCode: null,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return RequestCancelledException(
          message: 'Request was cancelled.',
          statusCode: null,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException(
            message: 'No internet connection. Please check your network.',
            statusCode: null,
          );
        }
        return UnknownException(
          message: 'An unexpected error occurred. Please try again.',
          statusCode: null,
        );
    }
  }

  /// Handle HTTP response errors based on status code
  ApiException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Try to extract error message from response
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage =
          responseData['message'] as String? ??
          responseData['error'] as String? ??
          responseData['detail'] as String?;
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: serverMessage ?? 'Invalid request. Please check your input.',
          statusCode: statusCode,
          errors: _extractValidationErrors(responseData),
        );

      case 401:
        return UnauthorizedException(
          message: serverMessage ?? 'Session expired. Please log in again.',
          statusCode: statusCode,
        );

      case 403:
        return ForbiddenException(
          message:
              serverMessage ??
              'You don\'t have permission to perform this action.',
          statusCode: statusCode,
        );

      case 404:
        return NotFoundException(
          message: serverMessage ?? 'The requested resource was not found.',
          statusCode: statusCode,
        );

      case 409:
        return ConflictException(
          message: serverMessage ?? 'A conflict occurred. Please try again.',
          statusCode: statusCode,
        );

      case 422:
        return ValidationException(
          message:
              serverMessage ?? 'Validation failed. Please check your input.',
          statusCode: statusCode,
          errors: _extractValidationErrors(responseData),
        );

      case 429:
        return TooManyRequestsException(
          message:
              serverMessage ?? 'Too many requests. Please wait and try again.',
          statusCode: statusCode,
        );

      case 500:
        return ServerException(
          message: serverMessage ?? 'Server error. Please try again later.',
          statusCode: statusCode,
        );

      case 502:
      case 503:
      case 504:
        return ServiceUnavailableException(
          message:
              serverMessage ??
              'Service temporarily unavailable. Please try again later.',
          statusCode: statusCode,
        );

      default:
        return UnknownException(
          message: serverMessage ?? 'An error occurred. Please try again.',
          statusCode: statusCode,
        );
    }
  }

  /// Extract validation errors from response data
  Map<String, List<String>>? _extractValidationErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final errors = data['errors'];
    if (errors is Map<String, dynamic>) {
      return errors.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.map((e) => e.toString()).toList());
        }
        return MapEntry(key, [value.toString()]);
      });
    }

    return null;
  }
}
