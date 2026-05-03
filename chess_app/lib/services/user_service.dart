import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class UserService {
  final ApiService _api;
  UserService(this._api);

  Future<UserModel> getProfile() async {
    try {
      final response = await _api.dio.get(ApiConstants.userProfile);
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      throw 'Profil alınamadı (${response.statusCode})';
    } on DioException catch (e) {
      throw e.message ?? 'Ağ hatası';
    }
  }

  Future<UserModel> updateProfile({String? username, String? email}) async {
    try {
      final response = await _api.dio.put(
        ApiConstants.userProfile,
        data: {
          if (username != null) 'username': username,
          if (email != null) 'email': email,
        },
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      final data = response.data;
      if (data is Map && data['message'] != null) throw data['message'];
      throw 'Güncelleme başarısız';
    } on DioException catch (e) {
      throw e.message ?? 'Ağ hatası';
    }
  }
}
