import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/game_models.dart';

class GameHistoryService {
  final ApiService _api;

  GameHistoryService(this._api);

  Future<String> createGame(CreateGamePayload payload) async {
    try {
      final response = await _api.dio.post(
        ApiConstants.games,
        data: payload.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['id'] as String;
      }

      throw 'Game could not be saved (${response.statusCode})';
    } on DioException catch (e) {
      throw e.message ?? 'Network error';
    }
  }

  Future<PagedGames> getMyGames({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _api.dio.get(
        ApiConstants.myGames,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.statusCode == 200) {
        return PagedGames.fromJson(response.data as Map<String, dynamic>);
      }

      throw 'History could not be loaded (${response.statusCode})';
    } on DioException catch (e) {
      throw e.message ?? 'Network error';
    }
  }

  Future<GameDetail> getGameById(String id) async {
    try {
      final response = await _api.dio.get(ApiConstants.gameById(id));

      if (response.statusCode == 200) {
        return GameDetail.fromJson(response.data as Map<String, dynamic>);
      }

      throw 'Game detail could not be loaded (${response.statusCode})';
    } on DioException catch (e) {
      throw e.message ?? 'Network error';
    }
  }
}
