// lib/core/api/api_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'http_client.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(httpClientProvider);
  return ApiService(dio);
}, name: 'apiService');

class ApiService {
  final Dio _dio;
  ApiService(this._dio);

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(path, queryParameters: query, options: options, cancelToken: cancelToken);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(path, data: data, options: options, cancelToken: cancelToken);
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(path, data: data, options: options, cancelToken: cancelToken);
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(path, data: data, options: options, cancelToken: cancelToken);
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(path, data: data, options: options, cancelToken: cancelToken);
  }
}

