import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/storage_keys.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/auth_response_model.dart';

class AuthService {
  final ApiService _api;
  final SecureStorageService _storage;

  AuthService(this._api, this._storage);

  Future<AuthResponseModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiConstants.register,
        data: {'username': username, 'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final auth = AuthResponseModel.fromJson(response.data);
        await _persistAuth(auth);
        return auth;
      }
      throw _extractError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final auth = AuthResponseModel.fromJson(response.data);
        await _persistAuth(auth);
        return auth;
      }
      throw _extractError(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> logout() async {
    await _storage.clear();
  }

  Future<String?> getToken() async => _storage.read(StorageKeys.token);

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _persistAuth(AuthResponseModel auth) async {
    await _storage.write(StorageKeys.token, auth.token);
    await _storage.write(StorageKeys.userId, auth.userId);
    await _storage.write(StorageKeys.username, auth.username);
    await _storage.write(StorageKeys.email, auth.email);
  }

  String _extractError(Response response) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Beklenmeyen hata (${response.statusCode})';
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Sunucuya bağlanılamadı. Backend çalışıyor mu?';
    }
    if (e.response != null) {
      return _extractError(e.response!);
    }
    return e.message ?? 'Bilinmeyen ağ hatası';
  }
}
