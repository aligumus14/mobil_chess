import 'dart:async';

import 'package:chess/chess.dart' as ch;
import 'package:flutter_chess_board/flutter_chess_board.dart' as fcb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/game_hub_service.dart';
import '../../auth/provider/auth_providers.dart';
import '../../game_history/provider/game_history_providers.dart';
import '../../profile/provider/profile_provider.dart';
import '../logic/online_time_control.dart';

class OnlineGameState {
  final String gameId;
  final String? yourColor;
  final String? opponentUsername;
  final int? opponentElo;
  final String fen;
  final String currentTurn;
  final List<String> sanHistory;
  final bool connected;
  final bool finished;
  final String? resultLabel;
  final String? terminationReason;
  final int? yourDelta;
  final int? opponentDelta;
  final String? errorMessage;
  final bool opponentOnline;
  final bool drawOfferReceived;
  final bool drawOfferSent;
  final bool sessionMissing;
  // Time control + clocks. Times are stored as a "baseline" remaining duration
  // valid at [turnStartedAt]. The side currently to move counts down from that
  // baseline; the other side's value is the live remaining time.
  final OnlineTimeControl? timeControl;
  final int whiteRemainingMs;
  final int blackRemainingMs;
  final DateTime? turnStartedAt;
  final DateTime? startupDeadlineUtc;

  const OnlineGameState({
    required this.gameId,
    this.yourColor,
    this.opponentUsername,
    this.opponentElo,
    required this.fen,
    required this.currentTurn,
    this.sanHistory = const [],
    this.connected = false,
    this.finished = false,
    this.resultLabel,
    this.terminationReason,
    this.yourDelta,
    this.opponentDelta,
    this.errorMessage,
    this.opponentOnline = false,
    this.drawOfferReceived = false,
    this.drawOfferSent = false,
    this.sessionMissing = false,
    this.timeControl,
    this.whiteRemainingMs = 0,
    this.blackRemainingMs = 0,
    this.turnStartedAt,
    this.startupDeadlineUtc,
  });

  factory OnlineGameState.initial(String gameId) => OnlineGameState(
    gameId: gameId,
    fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    currentTurn: 'white',
  );

  bool get isYourTurn =>
      !finished && connected && yourColor != null && yourColor == currentTurn;

  fcb.PlayerColor get boardOrientation =>
      yourColor == 'black' ? fcb.PlayerColor.black : fcb.PlayerColor.white;

  bool get waitingForStartup => !finished && sanHistory.length < 2;

  /// Live remaining time for [side] given [now]. Ticks down for the side to move.
  /// Clocks stay paused until both players have made their first move.
  int liveRemainingMs(String side, DateTime now) {
    final stored = side == 'white' ? whiteRemainingMs : blackRemainingMs;
    if (finished || turnStartedAt == null || side != currentTurn) return stored;
    if (waitingForStartup) return stored;
    final elapsed = now.difference(turnStartedAt!).inMilliseconds;
    final r = stored - elapsed;
    return r < 0 ? 0 : r;
  }

  int startupRemainingMs(DateTime now) {
    if (!waitingForStartup || startupDeadlineUtc == null) return 0;
    final remaining = startupDeadlineUtc!
        .difference(now.toUtc())
        .inMilliseconds;
    return remaining < 0 ? 0 : remaining;
  }

  OnlineGameState copyWith({
    String? yourColor,
    String? opponentUsername,
    int? opponentElo,
    String? fen,
    String? currentTurn,
    List<String>? sanHistory,
    bool? connected,
    bool? finished,
    String? resultLabel,
    String? terminationReason,
    int? yourDelta,
    int? opponentDelta,
    String? errorMessage,
    bool? opponentOnline,
    bool? drawOfferReceived,
    bool? drawOfferSent,
    bool? sessionMissing,
    OnlineTimeControl? timeControl,
    int? whiteRemainingMs,
    int? blackRemainingMs,
    DateTime? turnStartedAt,
    DateTime? startupDeadlineUtc,
    bool clearError = false,
  }) => OnlineGameState(
    gameId: gameId,
    yourColor: yourColor ?? this.yourColor,
    opponentUsername: opponentUsername ?? this.opponentUsername,
    opponentElo: opponentElo ?? this.opponentElo,
    fen: fen ?? this.fen,
    currentTurn: currentTurn ?? this.currentTurn,
    sanHistory: sanHistory ?? this.sanHistory,
    connected: connected ?? this.connected,
    finished: finished ?? this.finished,
    resultLabel: resultLabel ?? this.resultLabel,
    terminationReason: terminationReason ?? this.terminationReason,
    yourDelta: yourDelta ?? this.yourDelta,
    opponentDelta: opponentDelta ?? this.opponentDelta,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    opponentOnline: opponentOnline ?? this.opponentOnline,
    drawOfferReceived: drawOfferReceived ?? this.drawOfferReceived,
    drawOfferSent: drawOfferSent ?? this.drawOfferSent,
    sessionMissing: sessionMissing ?? this.sessionMissing,
    timeControl: timeControl ?? this.timeControl,
    whiteRemainingMs: whiteRemainingMs ?? this.whiteRemainingMs,
    blackRemainingMs: blackRemainingMs ?? this.blackRemainingMs,
    turnStartedAt: turnStartedAt ?? this.turnStartedAt,
    startupDeadlineUtc: startupDeadlineUtc ?? this.startupDeadlineUtc,
  );
}

class OnlineGameController extends Notifier<OnlineGameState> {
  late ch.Chess _game;
  late fcb.ChessBoardController boardController;
  GameHubService? _hub;
  bool _started = false;
  Timer? _tickTimer;

  @override
  OnlineGameState build() {
    _game = ch.Chess();
    boardController = fcb.ChessBoardController();
    ref.onDispose(() {
      _tickTimer?.cancel();
      boardController.dispose();
      _hub?.disconnect();
    });
    return OnlineGameState.initial('');
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      // Force a rebuild so liveRemainingMs returns a fresh value. We bump the
      // state by overwriting it with itself + an updated turnStartedAt-only-no-op
      // — actually we don't need to mutate anything: just notify by re-emitting
      // the same state. State equality is reference-based here so this works.
      if (!state.finished) {
        state = state.copyWith();
      } else {
        _tickTimer?.cancel();
      }
    });
  }

  Future<void> start(String gameId) async {
    // If we've already started for the same game, this is a no-op.
    // If a new gameId arrives (e.g. after a previous game ended and the user
    // requeues), tear everything down and rebuild against the new session.
    if (_started && state.gameId == gameId) return;
    if (_started) {
      await _hub?.disconnect();
      _hub = null;
      _game = ch.Chess();
      boardController.loadFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
    }
    _started = true;
    state = OnlineGameState.initial(gameId);
    _hub = ref.read(gameHubServiceProvider);

    try {
      await _hub!.connect();
      _hub!
        ..onGameState(_onGameState)
        ..onOpponentMove(_onOpponentMove)
        ..onMovePlayed(_onMovePlayed)
        ..onGameEnded(_onGameEnded)
        ..onDrawOffered((_) => state = state.copyWith(drawOfferReceived: true))
        ..onMatchFound((_) => state = state.copyWith(clearError: true))
        ..onOpponentConnected(
          () => state = state.copyWith(opponentOnline: true),
        )
        ..onOpponentDisconnected(
          () => state = state.copyWith(opponentOnline: false),
        )
        ..onReconnecting((_) {
          state = state.copyWith(
            connected: false,
            errorMessage: 'Baglanti yeniden kuruluyor...',
          );
        })
        ..onReconnected(() async {
          try {
            await _hub!.joinGame(state.gameId);
          } catch (e) {
            await _handleJoinFailure(e);
          }
        })
        ..onClose((err) {
          state = state.copyWith(
            connected: false,
            errorMessage: err?.toString() ?? 'Baglanti kapandi.',
          );
        });
      await _hub!.joinGame(state.gameId);
    } catch (e) {
      await _handleJoinFailure(e);
    }
  }

  void _onGameState(Map<String, dynamic> s) {
    final movesRaw = (s['moves'] as List?) ?? const [];
    final sans = movesRaw
        .map((m) => (m as Map)['san']?.toString() ?? '')
        .toList();

    final fen =
        s['currentFen']?.toString() ??
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    _game = ch.Chess.fromFEN(fen);
    boardController.loadFen(fen);

    final tc = OnlineTimeControl.fromWire(s['timeControl'] as int?);
    final whiteMs =
        (s['whiteRemainingMs'] as num?)?.toInt() ?? tc.initialSeconds * 1000;
    final blackMs =
        (s['blackRemainingMs'] as num?)?.toInt() ?? tc.initialSeconds * 1000;
    final turnStartedAt = _parseUtc(s['turnStartedAtUtc']) ?? DateTime.now();
    final startupDeadlineUtc = _parseUtc(s['startupDeadlineUtc']);

    state = state.copyWith(
      yourColor: s['yourColor']?.toString(),
      opponentUsername: s['yourColor'] == 'white'
          ? s['blackUsername']?.toString()
          : s['whiteUsername']?.toString(),
      opponentElo: s['yourColor'] == 'white'
          ? (s['blackElo'] as int?)
          : (s['whiteElo'] as int?),
      fen: fen,
      currentTurn: s['currentTurn']?.toString() ?? 'white',
      sanHistory: sans,
      connected: true,
      finished: s['finished'] == true,
      opponentOnline: s['opponentOnline'] == true,
      drawOfferReceived: false,
      drawOfferSent: false,
      sessionMissing: false,
      timeControl: tc,
      whiteRemainingMs: whiteMs,
      blackRemainingMs: blackMs,
      turnStartedAt: turnStartedAt,
      startupDeadlineUtc: startupDeadlineUtc,
      clearError: true,
    );

    if (!state.finished) _startTickTimer();
  }

  void _onOpponentMove(Map<String, dynamic> m) {
    final san = m['san']?.toString() ?? '';
    final fen = m['fenAfterMove']?.toString() ?? _game.fen;

    if (state.fen == fen) {
      return;
    }

    // Reconcile our local board with server state.
    if (_game.fen != fen) {
      _game = ch.Chess.fromFEN(fen);
      boardController.loadFen(fen);
    }

    final history = [...state.sanHistory, san];
    final nextTurn = state.currentTurn == 'white' ? 'black' : 'white';

    final whiteMs =
        (m['whiteRemainingMs'] as num?)?.toInt() ?? state.whiteRemainingMs;
    final blackMs =
        (m['blackRemainingMs'] as num?)?.toInt() ?? state.blackRemainingMs;
    final turnStartedAt = _parseUtc(m['turnStartedAtUtc']) ?? DateTime.now();
    final startupDeadlineUtc = _parseUtc(m['startupDeadlineUtc']);

    state = state.copyWith(
      fen: fen,
      currentTurn: nextTurn,
      sanHistory: history,
      drawOfferSent: false,
      drawOfferReceived: false,
      whiteRemainingMs: whiteMs,
      blackRemainingMs: blackMs,
      turnStartedAt: turnStartedAt,
      startupDeadlineUtc: startupDeadlineUtc ?? state.startupDeadlineUtc,
    );
  }

  /// Triggered for every move played in this game (including ours). Used to
  /// sync clocks with the server-authoritative values after our own move.
  void _onMovePlayed(Map<String, dynamic> m) {
    final whiteMs = (m['whiteRemainingMs'] as num?)?.toInt();
    final blackMs = (m['blackRemainingMs'] as num?)?.toInt();
    final turnStartedAt = _parseUtc(m['turnStartedAtUtc']);
    final startupDeadlineUtc = _parseUtc(m['startupDeadlineUtc']);
    if (whiteMs == null &&
        blackMs == null &&
        turnStartedAt == null &&
        startupDeadlineUtc == null) {
      return;
    }

    state = state.copyWith(
      whiteRemainingMs: whiteMs ?? state.whiteRemainingMs,
      blackRemainingMs: blackMs ?? state.blackRemainingMs,
      turnStartedAt: turnStartedAt ?? state.turnStartedAt,
      startupDeadlineUtc: startupDeadlineUtc ?? state.startupDeadlineUtc,
    );
  }

  static DateTime? _parseUtc(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toUtc();
    final s = v.toString();
    return DateTime.tryParse(s)?.toUtc();
  }

  void _onGameEnded(Map<String, dynamic> payload) {
    final result = payload['result']?.toString() ?? '';
    final reason = payload['reason']?.toString();
    final whiteDelta = payload['whiteDelta'] as int? ?? 0;
    final blackDelta = payload['blackDelta'] as int? ?? 0;

    final youAreWhite = state.yourColor == 'white';
    final yourDelta = youAreWhite ? whiteDelta : blackDelta;
    final oppDelta = youAreWhite ? blackDelta : whiteDelta;

    final label = _labelForResult(result, state.yourColor, reason);
    _tickTimer?.cancel();
    state = state.copyWith(
      finished: true,
      resultLabel: label,
      terminationReason: reason,
      yourDelta: yourDelta,
      opponentDelta: oppDelta,
      drawOfferReceived: false,
      drawOfferSent: false,
    );

    // Refresh history + profile on end.
    ref.invalidate(profileProvider);
    ref.invalidate(myGamesProvider);
  }

  String _labelForResult(
    String serverResult,
    String? yourColor,
    String? reason,
  ) {
    final r = serverResult.toLowerCase();
    final why = reason?.toLowerCase() ?? '';
    if (r.contains('cancel') || why.contains('start-timeout')) {
      return 'Oyun iptal edildi';
    }
    if (r.contains('draw')) return 'Beraberlik';
    final whiteWon = r.contains('white');
    if (yourColor == null) return whiteWon ? 'Beyaz kazandi' : 'Siyah kazandi';
    final youWon =
        (whiteWon && yourColor == 'white') ||
        (!whiteWon && yourColor == 'black');
    return youWon ? 'Kazandin' : 'Kaybettin';
  }

  Future<void> tryMakeMove() async {
    if (!state.isYourTurn || state.finished) return;

    final boardFen = boardController.game.fen;
    if (boardFen == _game.fen) return;

    final target = boardFen.split(' ').take(4).join(' ');
    ch.Move? matched;
    for (final move in _game.generate_moves()) {
      _game.move(move);
      final candidate = _game.fen.split(' ').take(4).join(' ');
      _game.undo_move();
      if (candidate == target) {
        matched = move;
        break;
      }
    }

    if (matched == null) {
      boardController.loadFen(_game.fen);
      return;
    }

    final from = matched.fromAlgebraic;
    final to = matched.toAlgebraic;
    _game.make_move(matched);

    final san = _lastSan();
    final fen = _game.fen;

    // Optimistically advance the local clock before the server echoes back.
    final myColor = state.currentTurn;
    final now = DateTime.now();
    final myRemainingLive = state.liveRemainingMs(myColor, now);
    final isFirstMoveForSide = myColor == 'white'
        ? state.sanHistory.isEmpty
        : state.sanHistory.length <= 1;
    final inc = isFirstMoveForSide
        ? 0
        : (state.timeControl?.incrementSeconds ?? 0) * 1000;
    final myNewRemaining = myRemainingLive + inc;
    final newWhite = myColor == 'white'
        ? myNewRemaining
        : state.whiteRemainingMs;
    final newBlack = myColor == 'black'
        ? myNewRemaining
        : state.blackRemainingMs;

    try {
      await _hub!.makeMove(state.gameId, from, to, san, fen);
      state = state.copyWith(
        fen: fen,
        currentTurn: state.currentTurn == 'white' ? 'black' : 'white',
        sanHistory: [...state.sanHistory, san],
        whiteRemainingMs: newWhite,
        blackRemainingMs: newBlack,
        turnStartedAt: now,
        drawOfferReceived: false,
        drawOfferSent: false,
        clearError: true,
      );
    } catch (e) {
      _game = ch.Chess.fromFEN(state.fen);
      boardController.loadFen(state.fen);
      state = state.copyWith(errorMessage: 'Hamle gonderilemedi: $e');
      return;
    }

    await _maybeReportEnd();
  }

  String _lastSan() {
    final history = _game.getHistory({'verbose': true});
    if (history.isEmpty) return '';
    final last = history.last as Map<dynamic, dynamic>;
    return (last['san'] as String?) ?? '';
  }

  Future<void> _maybeReportEnd() async {
    if (!_game.game_over) return;

    String result;
    String reason;
    if (_game.in_checkmate) {
      result = _game.turn == ch.Color.WHITE ? 'BlackWin' : 'WhiteWin';
      reason = 'Checkmate';
    } else if (_game.in_stalemate) {
      result = 'Draw';
      reason = 'Stalemate';
    } else if (_game.in_threefold_repetition) {
      result = 'Draw';
      reason = 'Threefold repetition';
    } else if (_game.insufficient_material) {
      result = 'Draw';
      reason = 'Insufficient material';
    } else if (_game.in_draw) {
      result = 'Draw';
      reason = '50-move rule';
    } else {
      return;
    }

    try {
      await _hub!.reportGameEnd(state.gameId, result, reason);
    } catch (_) {}
  }

  Future<void> resign() async {
    if (state.finished) return;
    try {
      await _hub!.resign(state.gameId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Pes etme gonderilemedi: $e');
    }
  }

  Future<void> offerDraw() async {
    if (state.finished || state.drawOfferSent) return;
    try {
      await _hub!.offerDraw(state.gameId);
      state = state.copyWith(drawOfferSent: true, clearError: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Beraberlik teklifi gonderilemedi: $e',
      );
    }
  }

  Future<void> acceptDraw() async {
    if (state.finished) return;
    try {
      await _hub!.acceptDraw(state.gameId);
      state = state.copyWith(drawOfferReceived: false, clearError: true);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Beraberlik kabul edilemedi: $e');
    }
  }

  void dismissDrawOffer() {
    if (!state.drawOfferReceived) return;
    state = state.copyWith(drawOfferReceived: false);
  }

  Future<void> _handleJoinFailure(Object error) async {
    if (_isMissingGameError(error)) {
      await _hub?.disconnect();
      state = state.copyWith(
        connected: false,
        sessionMissing: true,
        errorMessage: 'Bu online oyun artik aktif degil.',
      );
      return;
    }

    state = state.copyWith(
      connected: false,
      errorMessage: 'Baglanti hatasi: $error',
    );
  }

  bool _isMissingGameError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('oyun bulunamadi');
  }
}

final onlineGameProvider =
    NotifierProvider<OnlineGameController, OnlineGameState>(
      OnlineGameController.new,
    );
