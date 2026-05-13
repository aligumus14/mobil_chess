import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chess_ui.dart';
import '../../../models/user_model.dart';
import '../../../services/matchmaking_service.dart';
import '../../auth/provider/auth_providers.dart';
import '../../online_game/logic/online_time_control.dart';
import '../../profile/provider/profile_provider.dart';
import '../../shared/widgets/app_chrome.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _pollTimer;
  OnlineTimeControl? _busyTempo;
  OnlineTimeControl? _queuedTempo;
  String? _queueError;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startMatchmaking(OnlineTimeControl tempo) async {
    if (_busyTempo != null || _queuedTempo != null) return;
    setState(() {
      _busyTempo = tempo;
      _queueError = null;
    });

    try {
      final service = ref.read(matchmakingServiceProvider);
      final result = await service.join(timeControl: tempo);
      if (!mounted) return;

      if (result.matched && result.gameId != null) {
        _goToGame(result);
        return;
      }

      setState(() {
        _busyTempo = null;
        _queuedTempo = tempo;
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyTempo = null;
        _queuedTempo = null;
        _queueError = 'Eslesme basarisiz: $e';
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    final tempo = _queuedTempo;
    if (!mounted || tempo == null) return;

    try {
      final service = ref.read(matchmakingServiceProvider);
      final status = await service.status();
      if (!mounted) return;

      if (status.activeGameId != null) {
        _pollTimer?.cancel();
        _goToGame(JoinQueueResult(matched: true, gameId: status.activeGameId));
        return;
      }

      if (!status.inQueue) {
        final result = await service.join(timeControl: tempo);
        if (!mounted) return;
        if (result.matched && result.gameId != null) {
          _pollTimer?.cancel();
          _goToGame(result);
        }
      }
    } catch (_) {}
  }

  Future<void> _leaveQueue() async {
    _pollTimer?.cancel();
    try {
      await ref.read(matchmakingServiceProvider).leave();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _busyTempo = null;
      _queuedTempo = null;
    });
  }

  void _goToGame(JoinQueueResult result) {
    _pollTimer?.cancel();
    setState(() {
      _busyTempo = null;
      _queuedTempo = null;
    });
    context.push('/online-game/${result.gameId}');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      drawer: const ChessAppDrawer(currentIndex: 0),
      bottomNavigationBar: const ChessBottomNav(currentIndex: 0),
      body: ChessBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(profileProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const _TopBar(),
                const SizedBox(height: 26),
                SectionTitle(
                  title: 'Online Oyna',
                  icon: Icons.bolt_rounded,
                  trailing: _queuedTempo == null && _busyTempo == null
                      ? null
                      : TextButton(
                          onPressed: _leaveQueue,
                          child: const Text('Iptal'),
                        ),
                ),
                const SizedBox(height: 14),
                _QuickTempoGrid(
                  busyTempo: _busyTempo,
                  queuedTempo: _queuedTempo,
                  onSelected: _startMatchmaking,
                ),
                if (_queueError != null) ...[
                  const SizedBox(height: 14),
                  _ErrorPanel(message: _queueError!),
                ],
                if (_busyTempo != null || _queuedTempo != null) ...[
                  const SizedBox(height: 14),
                  _HomeQueuePanel(
                    tempo: _queuedTempo ?? _busyTempo!,
                    joining: _busyTempo != null,
                    onCancel: _leaveQueue,
                  ),
                ],
                const SizedBox(height: 18),
                _HomeActionButton(
                  icon: Icons.smart_toy_outlined,
                  title: 'Botla Oyna',
                  onTap: () => context.push('/offline-setup'),
                ),
                const SizedBox(height: 12),
                _HomeActionButton(
                  icon: Icons.history_rounded,
                  title: 'Oyun Gecmisi',
                  onTap: () => context.push('/games'),
                ),
                const SizedBox(height: 16),
                profileAsync.maybeWhen(
                  data: (user) => _SummaryPanel(user: user),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                profileAsync.maybeWhen(
                  data: (user) => _PerformancePanel(user: user),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return Row(
      children: [
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, size: 32),
          ),
        ),
        const SizedBox(width: 8),
        const KnightMark(size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Oyna',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const AppNotificationButton(),
      ],
    );
  }
}

class _QuickTempoGrid extends StatelessWidget {
  final OnlineTimeControl? busyTempo;
  final OnlineTimeControl? queuedTempo;
  final ValueChanged<OnlineTimeControl> onSelected;

  const _QuickTempoGrid({
    required this.busyTempo,
    required this.queuedTempo,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeTempo = queuedTempo ?? busyTempo;
    final enabled = activeTempo == null;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: OnlineTimeControl.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final tempo = OnlineTimeControl.values[index];
        final selected = activeTempo == tempo;
        return _QuickTempoTile(
          tempo: tempo,
          selected: selected,
          joining: busyTempo == tempo,
          enabled: enabled,
          onTap: () => onSelected(tempo),
        );
      },
    );
  }
}

class _QuickTempoTile extends StatelessWidget {
  final OnlineTimeControl tempo;
  final bool selected;
  final bool joining;
  final bool enabled;
  final VoidCallback onTap;

  const _QuickTempoTile({
    required this.tempo,
    required this.selected,
    required this.joining,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final background = selected ? colors.primary : colors.surface;
    final foreground = selected ? Colors.white : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.primary : colors.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.26 : 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (joining)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  _categoryIcon(tempo.category),
                  color: foreground,
                  size: 24,
                ),
              const SizedBox(height: 10),
              Text(
                tempo.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    return switch (category) {
      'Blitz' => Icons.bolt_rounded,
      'Rapid' => Icons.timer_outlined,
      _ => Icons.military_tech_outlined,
    };
  }
}

class _HomeQueuePanel extends StatelessWidget {
  final OnlineTimeControl tempo;
  final bool joining;
  final VoidCallback onCancel;

  const _HomeQueuePanel({
    required this.tempo,
    required this.joining,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return ChessPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: colors.primary,
              backgroundColor: colors.surfaceStrong,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  joining ? 'Eslesme baslatiliyor' : 'Rakip araniyor',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tempo.label,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(onPressed: onCancel, child: const Text('Iptal')),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HomeActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final foreground = colors.textPrimary;
    return ChessPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      color: colors.surface,
      border: Border.all(color: colors.divider),
      radius: 18,
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 38),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: foreground,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: foreground, size: 34),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final UserModel user;

  const _SummaryPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return ChessPanel(
      onTap: () => context.push('/games'),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Son Durum',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Tumunu Gor',
                style: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 116,
                height: 92,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Icon(
                    Icons.grid_on_rounded,
                    color: colors.boardLight,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.totalGames} oyun oynandi',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _InlineMetric(
                      icon: Icons.emoji_events_outlined,
                      label: 'Galibiyet',
                      value: '${user.wins}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _InlineMetric(
                      icon: Icons.percent_rounded,
                      label: 'Kazanma Orani',
                      value: '${user.winRate.toStringAsFixed(1)}%',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformancePanel extends StatelessWidget {
  final UserModel user;

  const _PerformancePanel({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final maxValue = [
      user.wins,
      user.losses,
      user.draws,
      1,
    ].reduce((a, b) => a > b ? a : b);

    return ChessPanel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performans',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PerformanceBar(
                  label: 'Galibiyet',
                  value: user.wins,
                  maxValue: maxValue,
                  color: AppColors.primary,
                  icon: Icons.trip_origin_rounded,
                ),
              ),
              Expanded(
                child: _PerformanceBar(
                  label: 'Maglubiyet',
                  value: user.losses,
                  maxValue: maxValue,
                  color: AppColors.error,
                  icon: Icons.close_rounded,
                ),
              ),
              Expanded(
                child: _PerformanceBar(
                  label: 'Beraberlik',
                  value: user.draws,
                  maxValue: maxValue,
                  color: AppColors.textSecondary,
                  icon: Icons.drag_handle_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final IconData icon;

  const _PerformanceBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final height = 38.0 + (70.0 * (value / maxValue));
    final displayColor = color == AppColors.primary
        ? colors.primary
        : color == AppColors.textSecondary
            ? colors.textSecondary
            : color;
    return Column(
      children: [
        Icon(icon, color: displayColor, size: 28),
        const SizedBox(height: 8),
        Container(
          height: 112,
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 34,
            height: height,
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$value',
          style: TextStyle(
            color: displayColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InlineMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final displayColor = color == AppColors.primary
        ? colors.primary
        : color == AppColors.textSecondary
            ? colors.textSecondary
            : color;
    return Row(
      children: [
        Icon(icon, color: displayColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: displayColor, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return ChessPanel(
      color: colors.error.withValues(alpha: 0.12),
      border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      child: Text(
        'Profil yuklenemedi: $message',
        style: TextStyle(color: colors.textPrimary),
      ),
    );
  }
}
