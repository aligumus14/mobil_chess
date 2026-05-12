import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chess_ui.dart';
import '../../../models/game_models.dart';
import '../provider/game_history_providers.dart';

enum _HistoryFilter { all, online, offline }

class GameHistoryScreen extends ConsumerStatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  ConsumerState<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends ConsumerState<GameHistoryScreen> {
  static const _pageSize = 20;
  int _page = 1;
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final request = GameHistoryPageRequest(page: _page, pageSize: _pageSize);
    final gamesAsync = ref.watch(myGamesProvider(request));

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Icon(Icons.castle_outlined),
        ),
        title: const Text('Oyun Gecmisi'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const ChessBottomNav(currentIndex: 1),
      body: ChessBackground(
        child: gamesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _HistoryError(
            message: '$error',
            onRetry: () => ref.invalidate(myGamesProvider(request)),
          ),
          data: (pagedGames) {
            final visibleGames = pagedGames.items
                .where(_matchesFilter)
                .toList();
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.refresh(myGamesProvider(request).future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                children: [
                  _HistoryFilters(
                    selected: _filter,
                    onChanged: (filter) => setState(() => _filter = filter),
                  ),
                  const SizedBox(height: 22),
                  _HistorySummaryCard(pagedGames: pagedGames),
                  const SizedBox(height: 16),
                  if (visibleGames.isEmpty)
                    const _EmptyHistoryState()
                  else
                    ...visibleGames.map(
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
            );
          },
        ),
      ),
    );
  }

  bool _matchesFilter(GameListItem game) {
    return switch (_filter) {
      _HistoryFilter.all => true,
      _HistoryFilter.online => game.gameType == ApiGameType.online,
      _HistoryFilter.offline => game.gameType != ApiGameType.online,
    };
  }
}

class _HistoryFilters extends StatelessWidget {
  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  const _HistoryFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'Tumu',
          selected: selected == _HistoryFilter.all,
          onTap: () => onChanged(_HistoryFilter.all),
        ),
        const SizedBox(width: 10),
        _FilterChip(
          label: 'Online',
          selected: selected == _HistoryFilter.online,
          onTap: () => onChanged(_HistoryFilter.online),
        ),
        const SizedBox(width: 10),
        _FilterChip(
          label: 'Offline',
          selected: selected == _HistoryFilter.offline,
          onTap: () => onChanged(_HistoryFilter.offline),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
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
    return ChessPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.primary, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kayitli Maclar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pagedGames.totalCount} mac, sayfa ${pagedGames.page}/${pagedGames.totalPages}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameHistoryCard extends StatelessWidget {
  final GameListItem game;
  final VoidCallback onTap;

  const _GameHistoryCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final result = _ResultView.fromGame(game);
    return ChessPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          PlayerAvatar(
            name: _opponentLabel(game),
            radius: 36,
            online: game.gameType == ApiGameType.online,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(result.icon, color: result.color, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      result.label,
                      style: TextStyle(
                        color: result.color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'vs ${_opponentLabel(game)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatGameDateTime(game.startedAt)} - ${game.moveCount} hamle',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _modeLabel(game),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _opponentLabel(GameListItem game) {
    return game.gameType == ApiGameType.online ? 'Rakip' : 'Stockfish';
  }

  String _modeLabel(GameListItem game) {
    if (game.gameType == ApiGameType.online) {
      return 'Online';
    }
    return switch (game.botDifficulty?.toLowerCase()) {
      'easy' => 'Kolay',
      'medium' => 'Orta',
      'hard' => 'Zor',
      _ => 'Bot',
    };
  }
}

class ResultBadge extends StatelessWidget {
  final ApiGameResult? result;
  final bool playerWon;

  const ResultBadge({super.key, required this.result, required this.playerWon});

  @override
  Widget build(BuildContext context) {
    final data = _ResultView.fromResult(result, playerWon);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: data.color, size: 17),
          const SizedBox(width: 7),
          Text(
            data.label,
            style: TextStyle(color: data.color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ResultView {
  final String label;
  final Color color;
  final IconData icon;

  const _ResultView({
    required this.label,
    required this.color,
    required this.icon,
  });

  factory _ResultView.fromGame(GameListItem game) {
    return _ResultView.fromResult(game.result, game.playerWon);
  }

  factory _ResultView.fromResult(ApiGameResult? result, bool playerWon) {
    if (result == ApiGameResult.draw) {
      return const _ResultView(
        label: 'Berabere',
        color: AppColors.textSecondary,
        icon: Icons.drag_handle_rounded,
      );
    }
    if (playerWon) {
      return const _ResultView(
        label: 'Kazandin',
        color: AppColors.primary,
        icon: Icons.emoji_events_outlined,
      );
    }
    return const _ResultView(
      label: 'Kaybettin',
      color: AppColors.error,
      icon: Icons.close_rounded,
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
              fontWeight: FontWeight.w700,
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

  const _HistoryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChessPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.sports_esports_outlined,
            size: 58,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 14),
          Text(
            'Henuz kayitli bir mac yok.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bir oyun tamamlandiginda burada gorunecek.',
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
