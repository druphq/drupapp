import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/dio_client.dart';
import '../api/api_response.dart';
import '../api/api_exceptions.dart';

export '../api/api_response.dart';
export '../api/api_exceptions.dart';
export '../api/dio_client.dart';

/// Main API Service for making HTTP requests
class ApiService {
  final Dio _dio;

  /// Create ApiService with default DioClient
  ApiService() : _dio = DioClient.instance.dio;

  /// Create ApiService with custom Dio instance
  ApiService.withDio(this._dio);

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool forceRefresh = false,
    bool noCache = false,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(
      () => _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      ),
      forceRefresh: forceRefresh,
      noCache: noCache,
    );
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      ),
    );
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      ),
    );
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      ),
    );
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      ),
    );
  }

  /// Upload a single file
  Future<ApiResponse<T>> uploadFile<T>(
    String path, {
    required File file,
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
    Map<String, dynamic>? headers,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(() async {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(file.path, filename: fileName),
        ...?additionalFields,
      });

      return _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data', ...?headers},
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    });
  }

  /// Upload multiple files
  Future<ApiResponse<T>> uploadFiles<T>(
    String path, {
    required List<File> files,
    String fieldName = 'files',
    Map<String, dynamic>? additionalFields,
    Map<String, dynamic>? headers,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    return _safeRequest<T>(() async {
      final multipartFiles = <MultipartFile>[];

      for (final file in files) {
        final fileName = file.path.split('/').last;
        multipartFiles.add(
          await MultipartFile.fromFile(file.path, filename: fileName),
        );
      }

      final formData = FormData.fromMap({
        fieldName: multipartFiles,
        ...?additionalFields,
      });

      return _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data', ...?headers},
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    });
  }

  /// Download a file
  Future<ApiResponse<File>> downloadFile(
    String urlPath,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    void Function(int received, int total)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(
        data: File(savePath),
        message: 'File downloaded successfully',
        statusCode: 200,
      );
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) {
        return ApiResponse.failure(
          message: error.message,
          statusCode: error.statusCode,
        );
      }
      return ApiResponse.failure(
        message: e.message ?? 'Download failed',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Execute request safely with error handling
  Future<ApiResponse<T>> _safeRequest<T>(
    Future<Response<dynamic>> Function() request, {
    bool forceRefresh = false,
    bool noCache = false,
  }) async {
    try {
      final response = await request();

      return ApiResponse.success(
        data: response.data as T?,
        statusCode: response.statusCode,
        message: _extractMessage(response.data),
        meta: _extractMeta(response.data),
        fromCache: response.extra['fromCache'] == true,
      );
    } on DioException catch (e) {
      debugPrint('API Request failed: ${e.message}');

      final error = e.error;
      if (error is ApiException) {
        return ApiResponse.failure(
          message: error.message,
          statusCode: error.statusCode,
        );
      }

      return ApiResponse.failure(
        message: e.message ?? 'An error occurred',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return ApiResponse.failure(message: e.toString());
    }
  }

  /// Extract message from response data
  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }

  /// Extract meta from response data
  Map<String, dynamic>? _extractMeta(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['meta'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Create a cancel token
  CancelToken createCancelToken() => CancelToken();

  /// Cancel a request
  void cancelRequest(CancelToken token, [String? reason]) {
    token.cancel(reason);
  }
}
