import 'dart:math';
import 'package:chess/chess.dart' as ch;
import 'game_models.dart';

/// Basit yerel satranç botu.
/// easy: random legal
/// medium: 1-ply material + küçük heuristik
/// hard: 2-ply minimax (alpha-beta)
class BotEngine {
  final _rand = Random();

  static final Map<ch.PieceType, int> _pieceValues = {
    ch.PieceType.PAWN: 100,
    ch.PieceType.KNIGHT: 320,
    ch.PieceType.BISHOP: 330,
    ch.PieceType.ROOK: 500,
    ch.PieceType.QUEEN: 900,
    ch.PieceType.KING: 20000,
  };

  /// FEN alır, bot için en iyi hamleyi seçip uygulanmış yeni pozisyonu döndürmek yerine
  /// seçilen hamle object'ini döndürür.
  ch.Move? pickMove(ch.Chess game, BotDifficulty difficulty) {
    final moves = game.generate_moves();
    if (moves.isEmpty) return null;

    return switch (difficulty) {
      BotDifficulty.easy => _pickRandom(moves),
      BotDifficulty.medium => _pickBestMaterial(game, moves),
      BotDifficulty.hard => _pickMinimax(game, moves, depth: 2),
    };
  }

  ch.Move _pickRandom(List<ch.Move> moves) =>
      moves[_rand.nextInt(moves.length)];

  ch.Move _pickBestMaterial(ch.Chess game, List<ch.Move> moves) {
    // Bot'un perspektifinden değerlendir — sıra kimdeyse o
    final botColor = game.turn;
    ch.Move? best;
    int bestScore = -999999;

    final shuffled = List<ch.Move>.from(moves)..shuffle(_rand);
    for (final m in shuffled) {
      game.move(m);
      final score = _evaluate(game, botColor);
      game.undo_move();
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best ?? moves.first;
  }

  ch.Move _pickMinimax(
    ch.Chess game,
    List<ch.Move> moves, {
    required int depth,
  }) {
    final botColor = game.turn;
    ch.Move? best;
    int bestScore = -999999;
    int alpha = -999999;
    const beta = 999999;

    final shuffled = List<ch.Move>.from(moves)..shuffle(_rand);
    for (final m in shuffled) {
      game.move(m);
      final score = -_negamax(game, depth - 1, -beta, -alpha, botColor);
      game.undo_move();
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
      if (score > alpha) alpha = score;
    }
    return best ?? moves.first;
  }

  int _negamax(
    ch.Chess game,
    int depth,
    int alpha,
    int beta,
    ch.Color rootColor,
  ) {
    if (depth == 0 || game.game_over) {
      final sign = game.turn == rootColor ? 1 : -1;
      return sign * _evaluate(game, rootColor);
    }
    int best = -999999;
    for (final m in game.generate_moves()) {
      game.move(m);
      final score = -_negamax(game, depth - 1, -beta, -alpha, rootColor);
      game.undo_move();
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  /// botColor perspektifinden skor. Pozitif = botColor için iyi.
  int _evaluate(ch.Chess game, ch.Color botColor) {
    if (game.in_checkmate) {
      // Sıra kimdeyse o mat olmuş
      return game.turn == botColor ? -100000 : 100000;
    }
    if (game.in_stalemate || game.in_draw) return 0;

    int score = 0;
    for (int sq = 0; sq < 128; sq++) {
      if ((sq & 0x88) != 0) continue;
      final piece = game.board[sq];
      if (piece == null) continue;
      final value = _pieceValues[piece.type] ?? 0;
      score += piece.color == botColor ? value : -value;
    }
    // Küçük mobility bonusu
    final mobility = game.generate_moves().length;
    score += game.turn == botColor ? mobility : -mobility;

    return score;
  }
}
