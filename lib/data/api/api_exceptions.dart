/// Base class for all API exceptions
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

/// Network connectivity exception
class NetworkException extends ApiException {
  const NetworkException({required super.message, super.statusCode});
}

/// Request timeout exception
class TimeoutException extends ApiException {
  const TimeoutException({required super.message, super.statusCode});
}

/// Request was cancelled
class RequestCancelledException extends ApiException {
  const RequestCancelledException({required super.message, super.statusCode});
}

/// Bad request (400)
class BadRequestException extends ApiException {
  final Map<String, List<String>>? errors;

  const BadRequestException({
    required super.message,
    super.statusCode,
    this.errors,
  });
}

/// Unauthorized (401)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({required super.message, super.statusCode});
}

/// Forbidden (403)
class ForbiddenException extends ApiException {
  const ForbiddenException({required super.message, super.statusCode});
}

/// Not found (404)
class NotFoundException extends ApiException {
  const NotFoundException({required super.message, super.statusCode});
}

/// Conflict (409)
class ConflictException extends ApiException {
  const ConflictException({required super.message, super.statusCode});
}

/// Validation error (422)
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    required super.message,
    super.statusCode,
    this.errors,
  });
}

/// Too many requests (429)
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException({required super.message, super.statusCode});
}

/// Internal server error (500)
class ServerException extends ApiException {
  const ServerException({required super.message, super.statusCode});
}

/// Service unavailable (502, 503, 504)
class ServiceUnavailableException extends ApiException {
  const ServiceUnavailableException({required super.message, super.statusCode});
}

/// Unknown/generic exception
class UnknownException extends ApiException {
  const UnknownException({required super.message, super.statusCode});
}
