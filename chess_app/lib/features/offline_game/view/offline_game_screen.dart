import 'package:chess/chess.dart' as ch;
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as fcb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/tap_to_move_board.dart';
import '../logic/game_models.dart';
import '../provider/offline_game_controller.dart';
import '../widgets/game_result_dialog.dart';
import '../widgets/move_list_panel.dart';
import '../widgets/status_bar.dart';

class OfflineGameScreen extends ConsumerStatefulWidget {
  const OfflineGameScreen({super.key});

  @override
  ConsumerState<OfflineGameScreen> createState() => _OfflineGameScreenState();
}

class _OfflineGameScreenState extends ConsumerState<OfflineGameScreen> {
  bool _resultShown = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(offlineGameProvider);
    final controller = ref.read(offlineGameProvider.notifier);

    if (!gameState.initialized) {
      return const Scaffold(body: Center(child: Text('Oyun baslatilmadi.')));
    }

    ref.listen(offlineGameProvider, (prev, next) {
      if (!_resultShown && next.result != null) {
        _resultShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResultDialog(next.result!);
        });
      }
      if (next.result == null) {
        _resultShown = false;
      }
    });

    final boardSize = MediaQuery.sizeOf(
      context,
    ).width.clamp(300.0, 520.0).toDouble();
    final playerName = gameState.playerSide == ch.Color.WHITE
        ? 'Sen'
        : 'Stockfish';
    final opponentName = gameState.playerSide == ch.Color.WHITE
        ? 'Stockfish'
        : 'Sen';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stockfish Arena',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              '${gameState.settings.difficulty.label} • ${gameState.settings.timeControl.label}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            tooltip: 'Yeniden Baslat',
            onPressed: () {
              _resultShown = false;
              controller.restart();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Pes Et',
            onPressed: gameState.isGameOver
                ? null
                : () => _confirmResign(controller),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          StatusBar(state: gameState),
          const SizedBox(height: 14),
          _ClockCard(
            label: opponentName,
            subtitle: gameState.playerSide == ch.Color.WHITE
                ? 'Siyah'
                : 'Beyaz',
            timeLeft: gameState.botTimeLeft,
            showClock: gameState.hasClock,
            active: !gameState.isPlayerTurn && !gameState.isGameOver,
            highlighted: gameState.botThinking,
            leading: Icons.smart_toy_outlined,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: AbsorbPointer(
              absorbing: !gameState.isPlayerTurn || gameState.botThinking,
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: TapToMoveBoard(
                  controller: controller.boardController,
                  boardOrientation: gameState.boardOrientation,
                  boardColor: fcb.BoardColor.brown,
                  enableUserMoves: true,
                  onMove: () => controller.onPlayerMoved(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ClockCard(
            label: playerName,
            subtitle: gameState.playerSide == ch.Color.WHITE
                ? 'Beyaz'
                : 'Siyah',
            timeLeft: gameState.playerTimeLeft,
            showClock: gameState.hasClock,
            active: gameState.isPlayerTurn && !gameState.isGameOver,
            highlighted: gameState.isPlayerTurn,
            leading: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          MoveListPanel(moves: gameState.sanHistory),
        ],
      ),
    );
  }

  Future<void> _confirmResign(OfflineGameController controller) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pes etmek istiyor musun?'),
        content: const Text(
          'Maci simdi bitirip yeni bir kurulum ekranina donebilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgec'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Pes Et'),
          ),
        ],
      ),
    );
    if (yes == true) {
      controller.resign();
    }
  }

  void _showResultDialog(GameResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameResultDialog(
        result: result,
        onRestart: () {
          Navigator.pop(ctx);
          _resultShown = false;
          ref.read(offlineGameProvider.notifier).restart();
        },
        onExit: () {
          Navigator.pop(ctx);
          if (context.mounted) {
            context.go('/home');
          }
        },
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final Duration timeLeft;
  final bool showClock;
  final bool active;
  final bool highlighted;
  final IconData leading;

  const _ClockCard({
    required this.label,
    required this.subtitle,
    required this.timeLeft,
    required this.showClock,
    required this.active,
    required this.highlighted,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final background = active ? AppColors.primaryDark : AppColors.surface;
    final foreground = active ? Colors.white : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? AppColors.accent : AppColors.divider,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.14)
                  : AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(leading, color: foreground),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: active ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              showClock ? _formatDuration(timeLeft) : 'Limitsiz',
              style: TextStyle(
                color: foreground,
                fontSize: showClock ? 24 : 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
