import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as fcb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/game_models.dart';
import '../provider/game_history_providers.dart';
import 'game_history_screen.dart';

class GameDetailScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameDetailScreen({
    super.key,
    required this.gameId,
  });

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  late final fcb.ChessBoardController _boardController;
  int? _selectedPly;
  String? _loadedFen;

  @override
  void initState() {
    super.initState();
    _boardController = fcb.ChessBoardController();
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(gameDetailProvider(widget.gameId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mac Detayi'),
        actions: [
          IconButton(
            tooltip: 'Analiz Et',
            onPressed: () => context.push('/games/${widget.gameId}/analysis'),
            icon: const Icon(Icons.analytics_outlined),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (detail) {
          final selectedPly = (_selectedPly ?? detail.moves.length).clamp(0, detail.moves.length);
          final selectedFen =
              selectedPly == 0 ? detail.startFen : detail.moves[selectedPly - 1].fenAfterMove;
          _syncBoard(selectedFen);

          final boardOrientation = detail.playerColor == 'black'
              ? fcb.PlayerColor.black
              : fcb.PlayerColor.white;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  ResultBadge(result: detail.result, playerWon: detail.playerWon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _detailSummary(detail),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatGameDateTime(detail.startedAt),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: fcb.ChessBoard(
                      controller: _boardController,
                      enableUserMoves: false,
                      boardColor: fcb.BoardColor.brown,
                      boardOrientation: boardOrientation,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: selectedPly > 0
                            ? () => setState(() => _selectedPly = selectedPly - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _positionLabel(detail, selectedPly),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedFen,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: selectedPly < detail.moves.length
                            ? () => setState(() => _selectedPly = selectedPly + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/games/${widget.gameId}/analysis'),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Stockfish ile Analiz Et'),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hamleler',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (detail.moves.isEmpty)
                        const Text(
                          'Bu macta kayitli hamle yok.',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        ..._buildMoveRows(detail, selectedPly),
                    ],
                  ),
                ),
              ),
              if ((detail.pgn ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: ExpansionTile(
                    title: const Text(
                      'PGN',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SelectableText(
                          detail.pgn!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _syncBoard(String fen) {
    if (_loadedFen == fen) {
      return;
    }

    _loadedFen = fen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _boardController.loadFen(fen);
    });
  }

  String _detailSummary(GameDetail detail) {
    final difficulty = switch (detail.botDifficulty?.toLowerCase()) {
      'easy' => 'Kolay',
      'medium' => 'Orta',
      'hard' => 'Zor',
      _ => 'Bilinmiyor',
    };
    final color = detail.playerColor == 'black' ? 'Siyah' : 'Beyaz';
    return '$difficulty bot - $color - ${detail.moves.length} yari hamle';
  }

  String _positionLabel(GameDetail detail, int selectedPly) {
    if (selectedPly == 0) {
      return 'Baslangic konumu';
    }

    final move = detail.moves[selectedPly - 1];
    final fullMoveNumber = ((selectedPly - 1) ~/ 2) + 1;
    return '$fullMoveNumber. ${move.san}';
  }

  List<Widget> _buildMoveRows(GameDetail detail, int selectedPly) {
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(
          onPressed: () => setState(() => _selectedPly = 0),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            side: BorderSide(
              color: selectedPly == 0 ? AppColors.primary : AppColors.divider,
              width: selectedPly == 0 ? 2 : 1,
            ),
          ),
          child: const Text('0. Baslangic konumu'),
        ),
      ),
    ];

    for (var index = 0; index < detail.moves.length; index += 2) {
      final whiteMove = detail.moves[index];
      final blackMove = index + 1 < detail.moves.length ? detail.moves[index + 1] : null;
      final fullMoveNumber = (index ~/ 2) + 1;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '$fullMoveNumber.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: _MoveButton(
                  label: whiteMove.san,
                  selected: selectedPly == index + 1,
                  onTap: () => setState(() => _selectedPly = index + 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: blackMove == null
                    ? const SizedBox.shrink()
                    : _MoveButton(
                        label: blackMove.san,
                        selected: selectedPly == index + 2,
                        onTap: () => setState(() => _selectedPly = index + 2),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}

class _MoveButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoveButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
      child: Text(label),
    );
  }
}
