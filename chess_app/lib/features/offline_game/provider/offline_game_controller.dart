import 'dart:async';
import 'dart:math';
import 'package:chess/chess.dart' as ch;
import 'package:flutter_chess_board/flutter_chess_board.dart' as fcb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/engine_models.dart';
import '../../../models/game_models.dart' as api;
import '../../auth/provider/auth_providers.dart';
import '../../game_history/provider/game_history_providers.dart';
import '../../profile/provider/profile_provider.dart';
import '../logic/game_models.dart';

class OfflineGameState {
  final GameSettings settings;
  final ch.Color playerSide;
  final String startFen;
  final String fen;
  final DateTime startedAt;
  final List<OfflineRecordedMove> moveHistory;
  final List<String> sanHistory;
  final bool botThinking;
  final GameResult? result;
  final bool initialized;
  final Duration playerTimeLeft;
  final Duration botTimeLeft;

  OfflineGameState({
    required this.settings,
    required this.playerSide,
    required this.startFen,
    required this.fen,
    required this.startedAt,
    required this.playerTimeLeft,
    required this.botTimeLeft,
    this.moveHistory = const [],
    this.sanHistory = const [],
    this.botThinking = false,
    this.result,
    this.initialized = false,
  });

  factory OfflineGameState.empty() {
    const initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    return OfflineGameState(
      settings: const GameSettings(),
      playerSide: ch.Color.WHITE,
      startFen: initialFen,
      fen: initialFen,
      startedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      playerTimeLeft: Duration.zero,
      botTimeLeft: Duration.zero,
    );
  }

  bool get isPlayerTurn {
    if (result != null || !initialized) {
      return false;
    }

    final turn = fen.split(' ')[1] == 'w' ? ch.Color.WHITE : ch.Color.BLACK;
    return turn == playerSide;
  }

  bool get isGameOver => result != null;
  bool get hasClock => settings.timeControl.initialDuration != null;

  fcb.PlayerColor get boardOrientation =>
      playerSide == ch.Color.WHITE ? fcb.PlayerColor.white : fcb.PlayerColor.black;

  OfflineGameState copyWith({
    GameSettings? settings,
    ch.Color? playerSide,
    String? startFen,
    String? fen,
    DateTime? startedAt,
    Duration? playerTimeLeft,
    Duration? botTimeLeft,
    List<OfflineRecordedMove>? moveHistory,
    List<String>? sanHistory,
    bool? botThinking,
    GameResult? result,
    bool? initialized,
    bool clearResult = false,
  }) =>
      OfflineGameState(
        settings: settings ?? this.settings,
        playerSide: playerSide ?? this.playerSide,
        startFen: startFen ?? this.startFen,
        fen: fen ?? this.fen,
        startedAt: startedAt ?? this.startedAt,
        playerTimeLeft: playerTimeLeft ?? this.playerTimeLeft,
        botTimeLeft: botTimeLeft ?? this.botTimeLeft,
        moveHistory: moveHistory ?? this.moveHistory,
        sanHistory: sanHistory ?? this.sanHistory,
        botThinking: botThinking ?? this.botThinking,
        result: clearResult ? null : (result ?? this.result),
        initialized: initialized ?? this.initialized,
      );
}

class OfflineGameController extends Notifier<OfflineGameState> {
  static const _initialFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  late ch.Chess _game;
  late fcb.ChessBoardController boardController;
  final _rand = Random();
  bool _historyPersistQueued = false;
  Timer? _clockTimer;

  @override
  OfflineGameState build() {
    _game = ch.Chess();
    boardController = fcb.ChessBoardController();
    ref.onDispose(() {
      _clockTimer?.cancel();
      boardController.dispose();
    });
    return OfflineGameState.empty();
  }

  void startNewGame(GameSettings settings) {
    _clockTimer?.cancel();
    _game = ch.Chess();
    boardController.resetBoard();
    _historyPersistQueued = false;

    final side = switch (settings.playerColor) {
      PlayerColor.white => ch.Color.WHITE,
      PlayerColor.black => ch.Color.BLACK,
      PlayerColor.random => _rand.nextBool() ? ch.Color.WHITE : ch.Color.BLACK,
    };

    final startedAt = DateTime.now().toUtc();
    final initialClock = settings.timeControl.initialDuration ?? Duration.zero;
    state = OfflineGameState(
      settings: settings,
      playerSide: side,
      startFen: _game.fen,
      fen: _game.fen,
      startedAt: startedAt,
      playerTimeLeft: initialClock,
      botTimeLeft: initialClock,
      initialized: true,
    );

    _startClockIfNeeded();
    if (side == ch.Color.BLACK) {
      Future.microtask(_makeBotMove);
    }
  }

  Future<void> onPlayerMoved() async {
    if (state.isGameOver || state.botThinking) {
      return;
    }

    final boardFen = boardController.game.fen;
    if (boardFen == _game.fen) {
      return;
    }

    final targetPosition = boardFen.split(' ').take(4).join(' ');
    ch.Move? matched;
    for (final move in _game.generate_moves()) {
      _game.move(move);
      final candidate = _game.fen.split(' ').take(4).join(' ');
      _game.undo_move();
      if (candidate == targetPosition) {
        matched = move;
        break;
      }
    }

    if (matched == null) {
      boardController.loadFen(_game.fen);
      return;
    }

    _game.make_move(matched);
    _appendLatestMove();
    _syncStateFromGame();
    if (_checkAndSetResult()) {
      return;
    }

    await _makeBotMove();
  }

  Future<void> _makeBotMove() async {
    if (state.isGameOver) {
      return;
    }

    state = state.copyWith(botThinking: true);
    try {
      final engineService = ref.read(engineServiceProvider);
      final response = await engineService.getBestMove(
        EngineBestMoveRequest(
          fen: _game.fen,
          difficulty: state.settings.difficulty.name,
        ),
      );

      final move = _findMoveByUci(response.bestMove);
      if (move == null) {
        _finishGame(
          const GameResult(
            outcome: GameOutcome.draw,
            reason: 'Engine move could not be applied',
            playerWon: false,
          ),
        );
        state = state.copyWith(botThinking: false);
        return;
      }

      _game.make_move(move);
      _appendLatestMove();
      boardController.loadFen(_game.fen);
      _syncStateFromGame();
      state = state.copyWith(botThinking: false);
      _checkAndSetResult();
    } catch (_) {
      _finishGame(
        const GameResult(
          outcome: GameOutcome.draw,
          reason: 'Stockfish unavailable',
          playerWon: false,
        ),
      );
      state = state.copyWith(botThinking: false);
    }
  }

  ch.Move? _findMoveByUci(String uci) {
    if (uci.length < 4) {
      return null;
    }

    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promotion = uci.length > 4 ? uci.substring(4).toLowerCase() : null;

    for (final move in _game.generate_moves()) {
      if (move.fromAlgebraic != from || move.toAlgebraic != to) {
        continue;
      }

      final movePromotion = move.promotion?.toString().split('.').last.toLowerCase();
      if ((promotion == null || promotion.isEmpty) && movePromotion == null) {
        return move;
      }

      if (promotion != null && movePromotion != null && movePromotion.startsWith(promotion)) {
        return move;
      }
    }

    return null;
  }

  void _startClockIfNeeded() {
    _clockTimer?.cancel();
    if (!state.hasClock) {
      return;
    }

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
  }

  void _tickClock() {
    if (!state.initialized || state.result != null || !state.hasClock) {
      return;
    }

    final activeTurn = _game.turn;
    if (activeTurn == state.playerSide) {
      final next = state.playerTimeLeft - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        final outcome =
            state.playerSide == ch.Color.WHITE ? GameOutcome.blackWin : GameOutcome.whiteWin;
        _finishGame(GameResult(outcome: outcome, reason: 'Time out', playerWon: false));
        state = state.copyWith(playerTimeLeft: Duration.zero);
        return;
      }
      state = state.copyWith(playerTimeLeft: next);
      return;
    }

    final next = state.botTimeLeft - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      final outcome =
          state.playerSide == ch.Color.WHITE ? GameOutcome.whiteWin : GameOutcome.blackWin;
      _finishGame(GameResult(outcome: outcome, reason: 'Time out', playerWon: true));
      state = state.copyWith(botTimeLeft: Duration.zero);
      return;
    }
    state = state.copyWith(botTimeLeft: next);
  }

  void _appendLatestMove() {
    final history = _game.getHistory({'verbose': true});
    if (history.isEmpty) {
      return;
    }

    final lastMove = history.last as Map<dynamic, dynamic>;
    final moveNumber = history.length;
    final recordedMove = OfflineRecordedMove(
      moveNumber: moveNumber,
      fromSquare: (lastMove['from'] as String?) ?? '',
      toSquare: (lastMove['to'] as String?) ?? '',
      san: (lastMove['san'] as String?) ?? '',
      fenAfterMove: _game.fen,
    );

    final updatedMoves = [...state.moveHistory];
    if (updatedMoves.length >= moveNumber) {
      updatedMoves[moveNumber - 1] = recordedMove;
    } else {
      updatedMoves.add(recordedMove);
    }

    state = state.copyWith(moveHistory: updatedMoves);
  }

  void _syncStateFromGame() {
    state = state.copyWith(
      fen: _game.fen,
      sanHistory: state.moveHistory.map((move) => move.san).toList(),
    );
  }

  bool _checkAndSetResult() {
    if (!_game.game_over) {
      return false;
    }

    GameOutcome outcome;
    String reason;

    if (_game.in_checkmate) {
      final loser = _game.turn;
      outcome = loser == ch.Color.WHITE ? GameOutcome.blackWin : GameOutcome.whiteWin;
      reason = 'Checkmate';
    } else if (_game.in_stalemate) {
      outcome = GameOutcome.draw;
      reason = 'Stalemate';
    } else if (_game.in_threefold_repetition) {
      outcome = GameOutcome.draw;
      reason = 'Threefold repetition';
    } else if (_game.insufficient_material) {
      outcome = GameOutcome.draw;
      reason = 'Insufficient material';
    } else if (_game.in_draw) {
      outcome = GameOutcome.draw;
      reason = '50-move rule';
    } else {
      return false;
    }

    final playerWon =
        (outcome == GameOutcome.whiteWin && state.playerSide == ch.Color.WHITE) ||
        (outcome == GameOutcome.blackWin && state.playerSide == ch.Color.BLACK);

    _finishGame(GameResult(outcome: outcome, reason: reason, playerWon: playerWon));
    return true;
  }

  void resign() {
    if (state.isGameOver) {
      return;
    }

    final outcome =
        state.playerSide == ch.Color.WHITE ? GameOutcome.blackWin : GameOutcome.whiteWin;
    _finishGame(GameResult(outcome: outcome, reason: 'Resigned', playerWon: false));
  }

  void restart() {
    startNewGame(state.settings);
  }

  void _finishGame(GameResult result) {
    if (state.result != null) {
      return;
    }

    _clockTimer?.cancel();
    final payload = _buildCreateGamePayload(result);
    state = state.copyWith(result: result, botThinking: false);

    if (_historyPersistQueued) {
      return;
    }

    _historyPersistQueued = true;
    unawaited(_persistCompletedGame(payload));
  }

  api.CreateGamePayload _buildCreateGamePayload(GameResult result) {
    final endedAt = DateTime.now().toUtc();
    final snapshot = _game.copy();
    final playerColor = state.playerSide == ch.Color.WHITE ? 'white' : 'black';
    final difficultyTag = state.settings.difficulty.name;
    final botLabel = 'Stockfish (${difficultyTag.toUpperCase()})';

    _applyPgnHeaders(
      snapshot: snapshot,
      endedAt: endedAt,
      playerColor: playerColor,
      botLabel: botLabel,
      difficultyTag: difficultyTag,
      result: result,
    );

    return api.CreateGamePayload(
      gameType: api.ApiGameType.offlineBot,
      playerColor: playerColor,
      botDifficulty: difficultyTag,
      timeControl: state.settings.timeControl.pgnValue,
      terminationReason: result.reason,
      result: _mapResult(result.outcome),
      startFen: state.startFen,
      finalFen: snapshot.fen,
      pgn: snapshot.pgn(),
      moves: state.moveHistory
          .map(
            (move) => api.CreateGameMovePayload(
              moveNumber: move.moveNumber,
              fromSquare: move.fromSquare,
              toSquare: move.toSquare,
              san: move.san,
              fenAfterMove: move.fenAfterMove,
            ),
          )
          .toList(),
      startedAt: state.startedAt,
      endedAt: endedAt,
    );
  }

  Future<void> _persistCompletedGame(api.CreateGamePayload payload) async {
    final service = ref.read(gameHistoryServiceProvider);
    try {
      await service.createGame(payload);
      ref.invalidate(profileProvider);
      ref.invalidate(myGamesProvider);
    } catch (_) {
      // Saving history should not block the game flow.
    }
  }

  api.ApiGameResult _mapResult(GameOutcome outcome) {
    return switch (outcome) {
      GameOutcome.whiteWin => api.ApiGameResult.whiteWin,
      GameOutcome.blackWin => api.ApiGameResult.blackWin,
      GameOutcome.draw || GameOutcome.ongoing => api.ApiGameResult.draw,
    };
  }

  String _pgnResult(GameOutcome outcome) {
    return switch (outcome) {
      GameOutcome.whiteWin => '1-0',
      GameOutcome.blackWin => '0-1',
      GameOutcome.draw || GameOutcome.ongoing => '1/2-1/2',
    };
  }

  String _pgnDate(DateTime dateTime) {
    final utc = dateTime.toUtc();
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}.$month.$day';
  }

  void _applyPgnHeaders({
    required ch.Chess snapshot,
    required DateTime endedAt,
    required String playerColor,
    required String botLabel,
    required String difficultyTag,
    required GameResult result,
  }) {
    snapshot.set_header([
      'Event',
      'Offline Bot Match',
      'Site',
      'ChessApp',
      'Date',
      _pgnDate(endedAt),
      'UTCDate',
      _pgnDate(endedAt),
      'UTCTime',
      _pgnTime(endedAt),
      'Round',
      '-',
      'White',
      playerColor == 'white' ? 'Player' : botLabel,
      'Black',
      playerColor == 'black' ? 'Player' : botLabel,
      'Result',
      _pgnResult(result.outcome),
      'PlayerColor',
      playerColor,
      'BotDifficulty',
      difficultyTag,
      'TimeControl',
      state.settings.timeControl.pgnValue,
      'Termination',
      result.reason,
    ]);

    if (state.startFen != _initialFen) {
      snapshot.set_header([
        'SetUp',
        '1',
        'FEN',
        state.startFen,
      ]);
    }
  }

  String _pgnTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

final offlineGameProvider = NotifierProvider<OfflineGameController, OfflineGameState>(
  OfflineGameController.new,
);
