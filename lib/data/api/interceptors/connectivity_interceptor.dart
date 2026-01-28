import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../api_exceptions.dart';

/// Interceptor that checks for internet connectivity before making requests
class ConnectivityInterceptor extends Interceptor {
  final Connectivity _connectivity;

  ConnectivityInterceptor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: NetworkException(
            message:
                'No internet connection. Please check your network and try again.',
            statusCode: null,
          ),
          type: DioExceptionType.connectionError,
        ),
      );
      return;
    }

    handler.next(options);
  }
}
