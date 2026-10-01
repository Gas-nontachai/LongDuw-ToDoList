import 'package:dio/dio.dart';

class ApiClient {
  static String get baseUrl {
    const value = String.fromEnvironment('API_BASE_URL');

    if (value.isEmpty) {
      throw StateError(
        'API_BASE_URL is not configured. '
        'Run Flutter with --dart-define-from-file=config/dev.json.',
      );
    }

    return value;
  }

  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<Response<dynamic>> get(String path) => _dio.get(path);
  Future<Response<dynamic>> post(String path, {Object? data}) =>
      _dio.post(path, data: data);
  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _dio.put(path, data: data);
  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}
