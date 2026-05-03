import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/game_models.dart';

class GameService {
  final ApiService _api;
  GameService(this._api);

  Future<String> createGame(CreateGamePayload payload) async {
    try {
      final res = await _api.dio.post(ApiConstants.games, data: payload.toJson());
      if (res.statusCode == 201 || res.statusCode == 200) {
        return res.data['id'] as String;
      }
      throw 'Oyun kaydedilemedi (${res.statusCode})';
    } on DioException catch (e) {
      throw e.message ?? 'Ağ hatası';
    }
  }

  Future<PagedGames> getMyGames({int page = 1, int pageSize = 20}) async {
    try {
      final res = await _api.dio.get(
        ApiConstants.myGames,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      if (res.statusCode == 200) {
        return PagedGames.fromJson(res.data as Map<String, dynamic>);
      }
      throw 'Geçmiş alınamadı (${res.statusCode})';
    } on DioException catch (e) {
      throw e.message ?? 'Ağ hatası';
    }
  }

  Future<GameDetail> getGameById(String id) async {
    try {
      final res = await _api.dio.get(ApiConstants.gameById(id));
      if (res.statusCode == 200) {
        return GameDetail.fromJson(res.data as Map<String, dynamic>);
      }
      throw 'Oyun detayı alınamadı (${res.statusCode})';
    } on DioException catch (e) {
      throw e.message ?? 'Ağ hatası';
    }
  }
}
