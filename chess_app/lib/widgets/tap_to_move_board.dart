import 'package:chess/chess.dart' as ch;
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as fcb;

/// Mevcut [fcb.ChessBoard]'in uzerine sokuldugunda tikla-tikla hamle ve
/// gecerli hamle gostergesi (yesil daireler) ekleyen bir sarmalayicidir.
/// Surukle-birak destegi paketten geldigi icin korunur.
class TapToMoveBoard extends StatefulWidget {
  final fcb.ChessBoardController controller;
  final fcb.PlayerColor boardOrientation;
  final fcb.BoardColor boardColor;
  final bool enableUserMoves;
  final VoidCallback? onMove;

  const TapToMoveBoard({
    super.key,
    required this.controller,
    required this.boardOrientation,
    this.boardColor = fcb.BoardColor.brown,
    this.enableUserMoves = true,
    this.onMove,
  });

  @override
  State<TapToMoveBoard> createState() => _TapToMoveBoardState();
}

class _TapToMoveBoardState extends State<TapToMoveBoard> {
  String? _selectedSquare;
  List<ch.Move> _legalMovesForSelected = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onBoardChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onBoardChanged);
    super.dispose();
  }

  void _onBoardChanged() {
    if (_selectedSquare != null) {
      setState(() {
        _selectedSquare = null;
        _legalMovesForSelected = const [];
      });
    }
  }

  bool get _flipped => widget.boardOrientation == fcb.PlayerColor.black;

  String _squareFromOffset(Offset localOffset, double boardSize) {
    final cell = boardSize / 8.0;
    final col = (localOffset.dx / cell).floor().clamp(0, 7);
    final row = (localOffset.dy / cell).floor().clamp(0, 7);
    final file = _flipped ? 7 - col : col;
    final rank = _flipped ? row : 7 - row;
    return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
  }

  void _onTapDown(TapDownDetails details, double boardSize) {
    if (!widget.enableUserMoves) return;
    final tapped = _squareFromOffset(details.localPosition, boardSize);
    final game = widget.controller.game;

    if (_selectedSquare != null) {
      final move = _findMove(_selectedSquare!, tapped);
      if (move != null) {
        _attemptMove(_selectedSquare!, tapped, move);
        return;
      }
    }

    final piece = _pieceAt(game, tapped);
    if (piece != null && piece.color == game.turn) {
      setState(() {
        _selectedSquare = tapped;
        _legalMovesForSelected = game
            .generate_moves({'square': tapped})
            .cast<ch.Move>();
      });
    } else {
      setState(() {
        _selectedSquare = null;
        _legalMovesForSelected = const [];
      });
    }
  }

  ch.Piece? _pieceAt(ch.Chess game, String square) {
    final idx = ch.Chess.SQUARES[square];
    if (idx == null) return null;
    return game.board[idx];
  }

  ch.Move? _findMove(String from, String to) {
    for (final m in _legalMovesForSelected) {
      if (m.fromAlgebraic == from && m.toAlgebraic == to) {
        return m;
      }
    }
    return null;
  }

  Future<void> _attemptMove(String from, String to, ch.Move move) async {
    final needsPromotion = move.promotion != null;
    if (needsPromotion) {
      final piece = await _askPromotion();
      if (piece == null) return;
      widget.controller.makeMoveWithPromotion(
        from: from,
        to: to,
        pieceToPromoteTo: piece,
      );
    } else {
      widget.controller.makeMove(from: from, to: to);
    }
    setState(() {
      _selectedSquare = null;
      _legalMovesForSelected = const [];
    });
    widget.onMove?.call();
  }

  Future<String?> _askPromotion() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Piyon terfisi'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _promoButton(ctx, 'Q', 'Vezir'),
            _promoButton(ctx, 'R', 'Kale'),
            _promoButton(ctx, 'B', 'Fil'),
            _promoButton(ctx, 'N', 'At'),
          ],
        ),
      ),
    );
  }

  Widget _promoButton(BuildContext ctx, String code, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => Navigator.pop(ctx, code),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        return Stack(
          children: [
            SizedBox(
              width: boardSize,
              height: boardSize,
              child: fcb.ChessBoard(
                controller: widget.controller,
                boardOrientation: widget.boardOrientation,
                boardColor: widget.boardColor,
                enableUserMoves: widget.enableUserMoves,
                onMove: widget.onMove,
              ),
            ),
            if (widget.enableUserMoves)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (d) => _onTapDown(d, boardSize),
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _MoveHintsPainter(
                        boardSize: boardSize,
                        selectedSquare: _selectedSquare,
                        legalMoves: _legalMovesForSelected,
                        flipped: _flipped,
                        game: widget.controller.game,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MoveHintsPainter extends CustomPainter {
  final double boardSize;
  final String? selectedSquare;
  final List<ch.Move> legalMoves;
  final bool flipped;
  final ch.Chess game;

  _MoveHintsPainter({
    required this.boardSize,
    required this.selectedSquare,
    required this.legalMoves,
    required this.flipped,
    required this.game,
  });

  Offset _center(String square) {
    final cell = boardSize / 8.0;
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square[1]) - 1;
    final col = flipped ? 7 - file : file;
    final row = flipped ? rank : 7 - rank;
    return Offset(col * cell + cell / 2, row * cell + cell / 2);
  }

  bool _hasPieceAt(String square) {
    final idx = ch.Chess.SQUARES[square];
    if (idx == null) return false;
    return game.board[idx] != null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = boardSize / 8.0;

    if (selectedSquare != null) {
      final highlight = Paint()
        ..color = Colors.amber.withValues(alpha: 0.45);
      final center = _center(selectedSquare!);
      final rect = Rect.fromCenter(
        center: center,
        width: cell,
        height: cell,
      );
      canvas.drawRect(rect, highlight);
    }

    final dot = Paint()..color = Colors.green.withValues(alpha: 0.55);
    final ring = Paint()
      ..color = Colors.green.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.08;

    final seen = <String>{};
    for (final m in legalMoves) {
      final to = m.toAlgebraic;
      if (!seen.add(to)) continue;
      final center = _center(to);
      if (_hasPieceAt(to)) {
        canvas.drawCircle(center, cell * 0.45, ring);
      } else {
        canvas.drawCircle(center, cell * 0.15, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_MoveHintsPainter old) {
    return old.boardSize != boardSize ||
        old.selectedSquare != selectedSquare ||
        old.legalMoves != legalMoves ||
        old.flipped != flipped;
  }
}
