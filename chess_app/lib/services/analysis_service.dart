import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/game_models.dart';

class AnalysisService {
  final ApiService _api;

  AnalysisService(this._api);

  Future<GameAnalysis> analyzeGame(String gameId, {bool force = false}) async {
    try {
      final response = await _api.dio.post(
        ApiConstants.analysisGame(gameId),
        queryParameters: {'force': force},
      );

      if (response.statusCode == 200) {
        return GameAnalysis.fromJson(response.data as Map<String, dynamic>);
      }

      throw _extractErrorMessage(response) ?? 'Analysis could not be created (${response.statusCode})';
    } on DioException catch (e) {
      throw _extractDioMessage(e);
    }
  }

  Future<GameAnalysis> getGameAnalysis(String gameId) async {
    try {
      final response = await _api.dio.get(ApiConstants.analysisGame(gameId));

      if (response.statusCode == 200) {
        return GameAnalysis.fromJson(response.data as Map<String, dynamic>);
      }

      throw _extractErrorMessage(response) ?? 'Analysis could not be loaded (${response.statusCode})';
    } on DioException catch (e) {
      throw _extractDioMessage(e);
    }
  }

  String _extractDioMessage(DioException exception) {
    final responseData = exception.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return exception.message ?? 'Network error';
  }

  String? _extractErrorMessage(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return null;
  }
}
