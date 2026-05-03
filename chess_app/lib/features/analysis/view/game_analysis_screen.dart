import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as fcb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/game_models.dart';
import '../../game_history/provider/game_history_providers.dart';
import '../provider/analysis_providers.dart';

class GameAnalysisScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameAnalysisScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameAnalysisScreen> createState() => _GameAnalysisScreenState();
}

class _GameAnalysisScreenState extends ConsumerState<GameAnalysisScreen> {
  late final fcb.ChessBoardController _boardController;
  int? _selectedPly;
  String? _loadedFen;
  bool _showCriticalOnly = false;

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
    final analysisAsync = ref.watch(gameAnalysisProvider(widget.gameId));

    if (detailAsync.isLoading || analysisAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (detailAsync.hasError) {
      return _ErrorScaffold(message: '${detailAsync.error}');
    }

    if (analysisAsync.hasError) {
      return _ErrorScaffold(message: '${analysisAsync.error}');
    }

    final detail = detailAsync.requireValue;
    final analysis = analysisAsync.requireValue;
    final selectedPly = (_selectedPly ?? detail.moves.length)
        .clamp(0, detail.moves.length)
        .toInt();
    final selectedFen = selectedPly == 0
        ? detail.startFen
        : detail.moves[selectedPly - 1].fenAfterMove;
    final selectedAnalysis = selectedPly == 0
        ? null
        : _analysisForPly(analysis, selectedPly);
    final selectedMoveDetail = selectedPly == 0
        ? null
        : detail.moves[selectedPly - 1];
    final summary = _AnalysisSummary.fromMoves(analysis.moves);

    _syncBoard(selectedFen);

    final boardOrientation = detail.playerColor == 'black'
        ? fcb.PlayerColor.black
        : fcb.PlayerColor.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mac Analizi'),
        actions: [
          IconButton(
            tooltip: 'Analizi yenile',
            onPressed: () =>
                ref.invalidate(gameAnalysisProvider(widget.gameId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            moveCount: analysis.moveCount,
            result: detail.result,
            playerColor: detail.playerColor,
            summary: summary,
          ),
          const SizedBox(height: 16),
          _BoardShowcase(
            controller: _boardController,
            boardOrientation: boardOrientation,
            analysis: selectedAnalysis,
            moveDetail: selectedMoveDetail,
          ),
          const SizedBox(height: 16),
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
          _SelectedAnalysisCard(
            analysis: selectedAnalysis,
            moveCount: detail.moves.length,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Hamle Analizi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Sadece hatalar'),
                        selected: _showCriticalOnly,
                        onSelected: (value) =>
                            setState(() => _showCriticalOnly = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (detail.moves.isEmpty)
                    const Text(
                      'Bu macta analiz edilecek hamle yok.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ..._buildMoveRows(detail, analysis, selectedPly),
                ],
              ),
            ),
          ),
        ],
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

  String _positionLabel(GameDetail detail, int selectedPly) {
    if (selectedPly == 0) {
      return 'Baslangic konumu';
    }

    final move = detail.moves[selectedPly - 1];
    final fullMoveNumber = ((selectedPly - 1) ~/ 2) + 1;
    return '$fullMoveNumber. ${move.san}';
  }

  MoveAnalysis? _analysisForPly(GameAnalysis analysis, int ply) {
    for (final item in analysis.moves) {
      if (item.moveNumber == ply) {
        return item;
      }
    }

    return null;
  }

  List<Widget> _buildMoveRows(
    GameDetail detail,
    GameAnalysis analysis,
    int selectedPly,
  ) {
    final analysisByPly = {
      for (final item in analysis.moves) item.moveNumber: item,
    };
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
      final blackMove = index + 1 < detail.moves.length
          ? detail.moves[index + 1]
          : null;
      final whiteAnalysis = analysisByPly[index + 1];
      final blackAnalysis = analysisByPly[index + 2];
      if (_showCriticalOnly &&
          !(whiteAnalysis?.isCritical == true ||
              blackAnalysis?.isCritical == true)) {
        continue;
      }

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
                child: _AnalysisMoveButton(
                  label: whiteMove.san,
                  analysis: whiteAnalysis,
                  selected: selectedPly == index + 1,
                  onTap: () => setState(() => _selectedPly = index + 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: blackMove == null
                    ? const SizedBox.shrink()
                    : _AnalysisMoveButton(
                        label: blackMove.san,
                        analysis: blackAnalysis,
                        selected: selectedPly == index + 2,
                        onTap: () => setState(() => _selectedPly = index + 2),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showCriticalOnly && widgets.length == 1) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Bu oyunda mistake veya blunder bulunamadi.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _BoardShowcase extends StatelessWidget {
  final fcb.ChessBoardController controller;
  final fcb.PlayerColor boardOrientation;
  final MoveAnalysis? analysis;
  final GameMoveDetail? moveDetail;

  const _BoardShowcase({
    required this.controller,
    required this.boardOrientation,
    required this.analysis,
    required this.moveDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: fcb.ChessBoard(
                              controller: controller,
                              enableUserMoves: false,
                              boardColor: fcb.BoardColor.brown,
                              boardOrientation: boardOrientation,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _BoardOverlay(
                                size: size,
                                orientation: boardOrientation,
                                bestMove: analysis?.bestMove,
                                playedFrom: moveDetail?.fromSquare,
                                playedTo: moveDetail?.toSquare,
                                classification: analysis?.classification,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: const [
                _LegendPill(
                  color: AppColors.success,
                  icon: Icons.arrow_outward_rounded,
                  label: 'Onerilen hamle oku',
                ),
                _LegendPill(
                  color: AppColors.primary,
                  icon: Icons.crop_square_rounded,
                  label: 'Oynanan hamle izleri',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardOverlay extends StatelessWidget {
  final double size;
  final fcb.PlayerColor orientation;
  final String? bestMove;
  final String? playedFrom;
  final String? playedTo;
  final AnalysisClassification? classification;

  const _BoardOverlay({
    required this.size,
    required this.orientation,
    required this.bestMove,
    required this.playedFrom,
    required this.playedTo,
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    final best = _ParsedMove.tryParse(bestMove);
    final overlays = <Widget>[];

    if (playedFrom != null && playedFrom!.length == 2) {
      overlays.add(_squareBorder(playedFrom!, AppColors.primary));
    }

    if (playedTo != null && playedTo!.length == 2) {
      overlays.add(
        _playedMoveSquare(
          playedTo!,
          _classificationColor(classification).withValues(alpha: 0.30),
        ),
      );
    }

    if (best != null) {
      overlays.add(
        Positioned.fill(
          child: CustomPaint(
            painter: _ArrowPainter(
              from: _squareCenter(best.from),
              to: _squareCenter(best.to),
              color: AppColors.success.withValues(alpha: 0.72),
            ),
          ),
        ),
      );
      overlays.add(
        _playedMoveSquare(best.to, AppColors.success.withValues(alpha: 0.22)),
      );
    }

    return Stack(children: overlays);
  }

  Widget _squareBorder(String square, Color color) {
    final rect = _squareRect(square);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _playedMoveSquare(String square, Color color) {
    final rect = _squareRect(square);
    return Positioned(
      left: rect.left + 6,
      top: rect.top + 6,
      width: rect.width - 12,
      height: rect.height - 12,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Rect _squareRect(String square) {
    final file = square.codeUnitAt(0) - 97;
    final rank = int.parse(square[1]) - 1;
    final squareSize = size / 8;

    final boardFile = orientation == fcb.PlayerColor.white ? file : 7 - file;
    final boardRank = orientation == fcb.PlayerColor.white ? 7 - rank : rank;

    return Rect.fromLTWH(
      boardFile * squareSize,
      boardRank * squareSize,
      squareSize,
      squareSize,
    );
  }

  Offset _squareCenter(String square) {
    final rect = _squareRect(square);
    return Offset(rect.left + (rect.width / 2), rect.top + (rect.height / 2));
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int moveCount;
  final ApiGameResult? result;
  final String playerColor;
  final _AnalysisSummary summary;

  const _SummaryCard({
    required this.moveCount,
    required this.result,
    required this.playerColor,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stockfish Analizi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '$moveCount yari hamle analiz edildi',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Bakis acisi: ${playerColor == 'black' ? 'Siyah' : 'Beyaz'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (result != null) ...[
              const SizedBox(height: 4),
              Text(
                'Sonuc: ${_resultLabel(result!)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryPill(
                  label: 'Best',
                  value: summary.best.toString(),
                  color: _classificationColor(AnalysisClassification.best),
                ),
                _SummaryPill(
                  label: 'Good',
                  value: summary.good.toString(),
                  color: _classificationColor(AnalysisClassification.good),
                ),
                _SummaryPill(
                  label: 'Inaccuracy',
                  value: summary.inaccuracy.toString(),
                  color: _classificationColor(
                    AnalysisClassification.inaccuracy,
                  ),
                ),
                _SummaryPill(
                  label: 'Mistake',
                  value: summary.mistake.toString(),
                  color: _classificationColor(AnalysisClassification.mistake),
                ),
                _SummaryPill(
                  label: 'Blunder',
                  value: summary.blunder.toString(),
                  color: _classificationColor(AnalysisClassification.blunder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _resultLabel(ApiGameResult result) {
    return switch (result) {
      ApiGameResult.whiteWin => 'Beyaz kazandi',
      ApiGameResult.blackWin => 'Siyah kazandi',
      ApiGameResult.draw => 'Berabere',
    };
  }
}

class _SelectedAnalysisCard extends StatelessWidget {
  final MoveAnalysis? analysis;
  final int moveCount;

  const _SelectedAnalysisCard({
    required this.analysis,
    required this.moveCount,
  });

  @override
  Widget build(BuildContext context) {
    final selected = analysis;
    if (moveCount == 0) {
      return const SizedBox.shrink();
    }

    if (selected == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Bir hamle secerek en iyi hamleyi, siniflandirmayi ve degerlendirmeyi gorebilirsiniz.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${selected.moveNumber}. hamle',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _ClassificationChip(classification: selected.classification),
              ],
            ),
            const SizedBox(height: 12),
            _MetricRow(label: 'Oynanan hamle', value: selected.playedMove),
            const SizedBox(height: 8),
            _MetricRow(label: 'En iyi hamle', value: selected.bestMove),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Degerlendirme',
              value: _formatEvaluation(selected.evaluation),
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Centipawn loss',
              value: selected.centipawnLoss.toStringAsFixed(0),
            ),
            const SizedBox(height: 12),
            Text(
              _explanation(selected),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatEvaluation(double evaluation) {
    final sign = evaluation >= 0 ? '+' : '';
    return '$sign${evaluation.toStringAsFixed(2)}';
  }

  static String _explanation(MoveAnalysis analysis) {
    return switch (analysis.classification) {
      AnalysisClassification.best =>
        'Bu hamle motorun onerisine cok yakin. Pozisyonu dogru yonetmis.',
      AnalysisClassification.good =>
        'Hamle saglam. En iyi secim olmayabilir ama ciddi bir kayip yaratmiyor.',
      AnalysisClassification.inaccuracy =>
        'Kucuk bir sapma var. Daha iyi bir devam yolu bulunabiliyordu.',
      AnalysisClassification.mistake =>
        'Bu hamle pozisyonda gozle gorulur bir kayip yaratiyor.',
      AnalysisClassification.blunder =>
        'Bu hamle buyuk bir hata. Daha dikkatli alternatif secmek gerekiyordu.',
    };
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AnalysisMoveButton extends StatelessWidget {
  final String label;
  final MoveAnalysis? analysis;
  final bool selected;
  final VoidCallback onTap;

  const _AnalysisMoveButton({
    required this.label,
    required this.analysis,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : _classificationColor(analysis?.classification).withValues(alpha: 0.7);

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : null,
        side: BorderSide(color: borderColor, width: selected ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (analysis != null) ...[
            const SizedBox(width: 8),
            Text(
              analysis!.centipawnLoss.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _classificationColor(analysis!.classification),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClassificationChip extends StatelessWidget {
  final AnalysisClassification classification;

  const _ClassificationChip({required this.classification});

  @override
  Widget build(BuildContext context) {
    final color = _classificationColor(classification);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _classificationLabel(classification),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;

  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mac Analizi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _AnalysisSummary {
  final int best;
  final int good;
  final int inaccuracy;
  final int mistake;
  final int blunder;

  const _AnalysisSummary({
    required this.best,
    required this.good,
    required this.inaccuracy,
    required this.mistake,
    required this.blunder,
  });

  factory _AnalysisSummary.fromMoves(List<MoveAnalysis> moves) {
    var best = 0;
    var good = 0;
    var inaccuracy = 0;
    var mistake = 0;
    var blunder = 0;

    for (final move in moves) {
      switch (move.classification) {
        case AnalysisClassification.best:
          best++;
          break;
        case AnalysisClassification.good:
          good++;
          break;
        case AnalysisClassification.inaccuracy:
          inaccuracy++;
          break;
        case AnalysisClassification.mistake:
          mistake++;
          break;
        case AnalysisClassification.blunder:
          blunder++;
          break;
      }
    }

    return _AnalysisSummary(
      best: best,
      good: good,
      inaccuracy: inaccuracy,
      mistake: mistake,
      blunder: blunder,
    );
  }
}

class _ParsedMove {
  final String from;
  final String to;

  const _ParsedMove({required this.from, required this.to});

  static _ParsedMove? tryParse(String? value) {
    if (value == null || value.length < 4) {
      return null;
    }

    return _ParsedMove(from: value.substring(0, 2), to: value.substring(2, 4));
  }
}

Color _classificationColor(AnalysisClassification? classification) {
  return switch (classification) {
    AnalysisClassification.best => AppColors.success,
    AnalysisClassification.good => const Color(0xFF74A84A),
    AnalysisClassification.inaccuracy => AppColors.warning,
    AnalysisClassification.mistake => const Color(0xFFE07B39),
    AnalysisClassification.blunder => AppColors.error,
    null => AppColors.divider,
  };
}

String _classificationLabel(AnalysisClassification classification) {
  return switch (classification) {
    AnalysisClassification.best => 'Best',
    AnalysisClassification.good => 'Good',
    AnalysisClassification.inaccuracy => 'Inaccuracy',
    AnalysisClassification.mistake => 'Mistake',
    AnalysisClassification.blunder => 'Blunder',
  };
}

class _ArrowPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  const _ArrowPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final direction = to - from;
    final length = direction.distance;
    if (length < 1) {
      return;
    }

    final unit = direction / length;
    final start = from + (unit * 12);
    final end = to - (unit * 16);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);

    final headSize = 18.0;
    final normal = Offset(-unit.dy, unit.dx);
    final tip = to - (unit * 6);
    final left = end - (unit * headSize) + (normal * 10);
    final right = end - (unit * headSize) - (normal * 10);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.color != color;
  }
}
