import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/game_models.dart';
import '../provider/game_history_providers.dart';

class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends ConsumerState<GameHistoryScreen> {
  static const _pageSize = 20;
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final request = GameHistoryPageRequest(page: _page, pageSize: _pageSize);
    final gamesAsync = ref.watch(myGamesProvider(request));

    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Gecmisi')),
      body: gamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _HistoryError(
          message: '$error',
          onRetry: () => ref.invalidate(myGamesProvider(request)),
        ),
        data: (pagedGames) => RefreshIndicator(
          onRefresh: () async => ref.refresh(myGamesProvider(request).future),
          child: pagedGames.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    _EmptyHistoryState(),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HistorySummaryCard(pagedGames: pagedGames),
                    const SizedBox(height: 16),
                    ...pagedGames.items.map(
                      (game) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GameHistoryCard(
                          game: game,
                          onTap: () => context.push('/games/${game.id}'),
                        ),
                      ),
                    ),
                    if (pagedGames.totalPages > 1) ...[
                      const SizedBox(height: 8),
                      _PaginationControls(
                        page: pagedGames.page,
                        totalPages: pagedGames.totalPages,
                        onPrevious: pagedGames.page > 1
                            ? () => setState(() => _page--)
                            : null,
                        onNext: pagedGames.page < pagedGames.totalPages
                            ? () => setState(() => _page++)
                            : null,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final PagedGames pagedGames;

  const _HistorySummaryCard({required this.pagedGames});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.history, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kayitli Maclar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pagedGames.totalCount} mac, sayfa ${pagedGames.page}/${pagedGames.totalPages}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHistoryCard extends StatelessWidget {
  final GameListItem game;
  final VoidCallback onTap;

  const _GameHistoryCard({
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ResultBadge(result: game.result, playerWon: game.playerWon),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _subtitle(game),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                '${game.moveCount} yari hamle • ${formatGameDateTime(game.startedAt)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(GameListItem game) {
    final difficulty = switch (game.botDifficulty?.toLowerCase()) {
      'easy' => 'Kolay',
      'medium' => 'Orta',
      'hard' => 'Zor',
      _ => 'Bilinmiyor',
    };
    final color = game.playerColor == 'black' ? 'Siyah' : 'Beyaz';
    final type = game.gameType == ApiGameType.offlineBot ? 'Bot Maci' : 'Mac';
    return '$type • $difficulty • $color';
  }
}

class ResultBadge extends StatelessWidget {
  final ApiGameResult? result;
  final bool playerWon;

  const ResultBadge({
    super.key,
    required this.result,
    required this.playerWon,
  });

  @override
  Widget build(BuildContext context) {
    final data = switch (result) {
      ApiGameResult.draw => ('Berabere', AppColors.textSecondary, Icons.handshake_outlined),
      _ when playerWon => ('Galibiyet', AppColors.primary, Icons.emoji_events_outlined),
      _ => ('Maglubiyet', AppColors.error, Icons.flag_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.$3, color: data.$2, size: 16),
          const SizedBox(width: 6),
          Text(
            data.$1,
            style: TextStyle(color: data.$2, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationControls({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Onceki'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$page / $totalPages',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sonraki'),
          ),
        ),
      ],
    );
  }
}

class _HistoryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HistoryError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: const [
          Icon(Icons.sports_esports_outlined, size: 52, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'Henuz kayitli bir mac yok.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Bilgisayara karsi bir oyun bitirdiginde burada otomatik olarak gorunecek.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String formatGameDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}
