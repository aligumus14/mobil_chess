import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/storage_keys.dart';
import '../core/storage/secure_storage_service.dart';

typedef MoveCallback = void Function(Map<String, dynamic> move);
typedef GameEndedCallback = void Function(Map<String, dynamic> payload);
typedef GameStateCallback = void Function(Map<String, dynamic> state);
typedef SimpleCallback = void Function();
typedef MatchFoundCallback = void Function(Map<String, dynamic> payload);
typedef AsyncSimpleCallback = Future<void> Function();

class GameHubService {
  final SecureStorageService _storage;
  HubConnection? _connection;

  GameHubService(this._storage);

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  String _resolveHubUrl() {
    if (kIsWeb) return ApiConstants.gameHubWeb;
    try {
      if (Platform.isAndroid) return ApiConstants.gameHubAndroid;
    } catch (_) {}
    return ApiConstants.gameHub;
  }

  Future<void> connect() async {
    if (_connection != null && isConnected) return;

    final url = _resolveHubUrl();
    final options = HttpConnectionOptions(
      accessTokenFactory: () async {
        final t = await _storage.read(StorageKeys.token);
        return t ?? '';
      },
    );

    final conn = HubConnectionBuilder()
        .withUrl(url, options: options)
        .withAutomaticReconnect()
        .build();

    _connection = conn;
    await conn.start();
  }

  Future<void> disconnect() async {
    final conn = _connection;
    _connection = null;
    if (conn != null) {
      try {
        await conn.stop();
      } catch (_) {}
    }
  }

  Future<void> joinGame(String gameId) async {
    await _connection?.invoke('JoinGame', args: [gameId]);
  }

  Future<void> makeMove(
    String gameId,
    String from,
    String to,
    String san,
    String fenAfterMove,
  ) async {
    await _connection?.invoke(
      'MakeMove',
      args: [gameId, from, to, san, fenAfterMove],
    );
  }

  Future<void> reportGameEnd(String gameId, String result, String reason) async {
    await _connection?.invoke('ReportGameEnd', args: [gameId, result, reason]);
  }

  Future<void> resign(String gameId) async {
    await _connection?.invoke('Resign', args: [gameId]);
  }

  Future<void> offerDraw(String gameId) async {
    await _connection?.invoke('OfferDraw', args: [gameId]);
  }

  Future<void> acceptDraw(String gameId) async {
    await _connection?.invoke('AcceptDraw', args: [gameId]);
  }

  void onGameState(GameStateCallback cb) {
    _connection?.on('GameState', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is Map) cb(Map<String, dynamic>.from(first));
    });
  }

  void onMovePlayed(MoveCallback cb) {
    _connection?.on('MovePlayed', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is Map) cb(Map<String, dynamic>.from(first));
    });
  }

  void onOpponentMove(MoveCallback cb) {
    _connection?.on('OpponentMove', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is Map) cb(Map<String, dynamic>.from(first));
    });
  }

  void onGameEnded(GameEndedCallback cb) {
    _connection?.on('GameEnded', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is Map) cb(Map<String, dynamic>.from(first));
    });
  }

  void onOpponentDisconnected(SimpleCallback cb) {
    _connection?.on('OpponentDisconnected', (_) => cb());
  }

  void onOpponentConnected(SimpleCallback cb) {
    _connection?.on('OpponentConnected', (_) => cb());
  }

  void onDrawOffered(MatchFoundCallback cb) {
    _connection?.on('DrawOffered', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is Map) cb(Map<String, dynamic>.from(first));
    });
  }

  void onMatchFound(MatchFoundCallback cb) {
    _connection?.on('MatchFound', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is Map) cb(Map<String, dynamic>.from(first));
    });
  }

  void onClose(void Function(Exception? error) cb) {
    _connection?.onclose(({Exception? error}) => cb(error));
  }

  void onReconnecting(void Function(Exception? error) cb) {
    _connection?.onreconnecting(({Exception? error}) => cb(error));
  }

  void onReconnected(AsyncSimpleCallback cb) {
    _connection?.onreconnected(({connectionId}) {
      unawaited(cb());
    });
  }
}
