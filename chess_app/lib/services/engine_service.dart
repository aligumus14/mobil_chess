import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/engine_models.dart';

class EngineService {
  final ApiService _api;

  EngineService(this._api);

  Future<EngineBestMoveResponse> getBestMove(EngineBestMoveRequest request) async {
    try {
      final response = await _api.dio.post(
        ApiConstants.engineBestMove,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return EngineBestMoveResponse.fromJson(response.data as Map<String, dynamic>);
      }

      throw _extractErrorMessage(response) ?? 'Best move could not be loaded (${response.statusCode})';
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
