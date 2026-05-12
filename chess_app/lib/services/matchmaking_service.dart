import 'package:dio/dio.dart';
import '../config/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../features/online_game/logic/online_time_control.dart';

class JoinQueueResult {
  final bool matched;
  final bool resumed;
  final String? gameId;
  final String? opponentId;
  final String? opponentUsername;
  final int? opponentElo;
  final String? assignedColor;
  final String? startFen;
  final OnlineTimeControl? timeControl;
  final int? initialSeconds;
  final int? incrementSeconds;

  JoinQueueResult({
    required this.matched,
    this.resumed = false,
    this.gameId,
    this.opponentId,
    this.opponentUsername,
    this.opponentElo,
    this.assignedColor,
    this.startFen,
    this.timeControl,
    this.initialSeconds,
    this.incrementSeconds,
  });

  factory JoinQueueResult.fromJson(Map<String, dynamic> j) => JoinQueueResult(
    matched: j['matched'] as bool? ?? false,
    resumed: j['resumed'] as bool? ?? false,
    gameId: j['gameId'] as String?,
    opponentId: j['opponentId'] as String?,
    opponentUsername: j['opponentUsername'] as String?,
    opponentElo: j['opponentElo'] as int?,
    assignedColor: j['assignedColor'] as String?,
    startFen: j['startFen'] as String?,
    timeControl: j['timeControl'] == null
        ? null
        : OnlineTimeControl.fromWire(j['timeControl'] as int?),
    initialSeconds: j['initialSeconds'] as int?,
    incrementSeconds: j['incrementSeconds'] as int?,
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

  factory MatchmakingStatus.fromJson(Map<String, dynamic> j) =>
      MatchmakingStatus(
        inQueue: j['inQueue'] as bool? ?? false,
        queuedAt: j['queuedAt'] == null
            ? null
            : DateTime.tryParse(j['queuedAt'] as String),
        eloSnapshot: j['eloSnapshot'] as int?,
        activeGameId: j['activeGameId'] as String?,
      );
}

class MatchmakingService {
  final ApiService _api;
  MatchmakingService(this._api);

  Future<JoinQueueResult> join({OnlineTimeControl? timeControl}) async {
    final body = {
      'timeControl': (timeControl ?? OnlineTimeControl.blitz5).wireValue,
    };
    final res = await _api.dio.post(ApiConstants.matchmakingJoin, data: body);
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

  Future<bool> abandon() async {
    final res = await _api.dio.post(ApiConstants.matchmakingAbandon);
    _ensureOk(res);
    return (res.data['abandoned'] as bool?) ?? false;
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
