import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as fcb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/online_game_controller.dart';

class OnlineGameScreen extends ConsumerStatefulWidget {
  final String gameId;
  const OnlineGameScreen({super.key, required this.gameId});

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  bool _endDialogShown = false;
  bool _drawDialogShown = false;
  bool _sessionMissingDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onlineGameProvider.notifier).start(widget.gameId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onlineGameProvider);
    final controller = ref.read(onlineGameProvider.notifier);

    ref.listen(onlineGameProvider, (prev, next) {
      if (!_endDialogShown && next.finished && next.resultLabel != null) {
        _endDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showEndDialog(next));
      }

      if (!_drawDialogShown &&
          next.drawOfferReceived &&
          prev?.drawOfferReceived != true) {
        _drawDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showDrawOfferDialog(controller));
      }

      if (!_sessionMissingDialogShown &&
          next.sessionMissing &&
          prev?.sessionMissing != true) {
        _sessionMissingDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showSessionMissingDialog());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.opponentUsername == null
            ? 'Online Mac'
            : '${state.opponentUsername} (${state.opponentElo ?? '-'})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.handshake_outlined),
            tooltip: 'Beraberlik Teklif Et',
            onPressed: state.finished || state.drawOfferSent
                ? null
                : () => _offerDraw(controller),
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Pes Et',
            onPressed: state.finished ? null : () => _confirmResign(controller),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = constraints.maxWidth.clamp(280.0, 520.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusCard(state: state),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: boardSize,
                    child: AbsorbPointer(
                      absorbing: !state.isYourTurn,
                      child: fcb.ChessBoard(
                        controller: controller.boardController,
                        boardOrientation: state.boardOrientation,
                        boardColor: fcb.BoardColor.brown,
                        enableUserMoves: true,
                        onMove: () => controller.tryMakeMove(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _MoveList(moves: state.sanHistory),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmResign(OnlineGameController controller) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pes etmek istiyor musun?'),
        content: const Text('Oyun biter ve ELO kaybedersin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgec'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pes Et'),
          ),
        ],
      ),
    );
    if (yes == true) await controller.resign();
  }

  Future<void> _offerDraw(OnlineGameController controller) async {
    await controller.offerDraw();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Beraberlik teklifi gonderildi.')),
    );
  }

  Future<void> _showDrawOfferDialog(OnlineGameController controller) async {
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Beraberlik Teklifi'),
        content: const Text('Rakibin beraberlik teklif etti. Kabul ediyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hayir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kabul Et'),
          ),
        ],
      ),
    );

    _drawDialogShown = false;
    if (accept == true) {
      await controller.acceptDraw();
    } else {
      controller.dismissDrawOffer();
    }
  }

  void _showEndDialog(OnlineGameState state) {
    final yourDelta = state.yourDelta ?? 0;
    final sign = yourDelta >= 0 ? '+' : '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(state.resultLabel ?? 'Oyun Bitti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.terminationReason != null)
              Text('Sebep: ${state.terminationReason}'),
            const SizedBox(height: 8),
            Text('ELO degisimi: $sign$yourDelta'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.mounted) context.go('/home');
            },
            child: const Text('Ana Menu'),
          ),
        ],
      ),
    );
  }

  void _showSessionMissingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Oyun Artik Aktif Degil'),
        content: const Text(
          'Bu online oyun oturumu kapanmis veya sunucu yeniden baslatilmis. Ana menuye donulecek.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.mounted) context.go('/home');
            },
            child: const Text('Ana Menu'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final OnlineGameState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    String title;
    if (!state.connected) {
      title = 'Baglaniyor...';
    } else if (state.finished) {
      title = state.resultLabel ?? 'Bitti';
    } else if (state.isYourTurn) {
      title = 'Senin siran';
    } else {
      title = 'Rakibin sirasi';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              state.finished
                  ? Icons.flag
                  : (state.isYourTurn ? Icons.play_arrow : Icons.hourglass_top),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            Text(state.yourColor ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _MoveList extends StatelessWidget {
  final List<String> moves;
  const _MoveList({required this.moves});

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Henuz hamle yok.'),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: List.generate(moves.length, (i) {
            final label =
                '${(i ~/ 2) + 1}${i.isEven ? '.' : '...'} ${moves[i]}';
            return Chip(label: Text(label));
          }),
        ),
      ),
    );
  }
}
