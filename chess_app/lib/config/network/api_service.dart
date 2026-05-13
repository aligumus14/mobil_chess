import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/storage/secure_storage_service.dart';

class ApiService {
  late final Dio _dio;
  final SecureStorageService _storage;

  ApiService(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(_storage));
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  Dio get dio => _dio;

  String _resolveBaseUrl() {
    if (kIsWeb) return ApiConstants.baseUrlWeb;
    try {
      if (Platform.isAndroid) return ApiConstants.baseUrlAndroid;
    } catch (_) {}
    return ApiConstants.baseUrl;
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(StorageKeys.token);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
