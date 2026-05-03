import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';

class JoinQueueResult {
  final bool matched;
  final String? gameId;
  final String? opponentId;
  final String? opponentUsername;
  final int? opponentElo;
  final String? assignedColor;
  final String? startFen;

  JoinQueueResult({
    required this.matched,
    this.gameId,
    this.opponentId,
    this.opponentUsername,
    this.opponentElo,
    this.assignedColor,
    this.startFen,
  });

  factory JoinQueueResult.fromJson(Map<String, dynamic> j) => JoinQueueResult(
        matched: j['matched'] as bool? ?? false,
        gameId: j['gameId'] as String?,
        opponentId: j['opponentId'] as String?,
        opponentUsername: j['opponentUsername'] as String?,
        opponentElo: j['opponentElo'] as int?,
        assignedColor: j['assignedColor'] as String?,
        startFen: j['startFen'] as String?,
      );
}

class MatchmakingStatus {
  final bool inQueue;
  final DateTime? queuedAt;
  final int? eloSnapshot;
  final String? activeGameId;

  MatchmakingStatus({
    required this.inQueue,
    this.queuedAt,
    this.eloSnapshot,
    this.activeGameId,
  });

  factory MatchmakingStatus.fromJson(Map<String, dynamic> j) => MatchmakingStatus(
        inQueue: j['inQueue'] as bool? ?? false,
        queuedAt: j['queuedAt'] == null ? null : DateTime.tryParse(j['queuedAt'] as String),
        eloSnapshot: j['eloSnapshot'] as int?,
        activeGameId: j['activeGameId'] as String?,
      );
}

class MatchmakingService {
  final ApiService _api;
  MatchmakingService(this._api);

  Future<JoinQueueResult> join() async {
    final res = await _api.dio.post(ApiConstants.matchmakingJoin);
    _ensureOk(res);
    return JoinQueueResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> leave() async {
    final res = await _api.dio.post(ApiConstants.matchmakingLeave);
    _ensureOk(res);
    return (res.data['removed'] as bool?) ?? false;
  }

  Future<MatchmakingStatus> status() async {
    final res = await _api.dio.post(ApiConstants.matchmakingStatus);
    _ensureOk(res);
    return MatchmakingStatus.fromJson(res.data as Map<String, dynamic>);
  }

  void _ensureOk(Response res) {
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        message: res.data?.toString(),
      );
    }
  }
}
