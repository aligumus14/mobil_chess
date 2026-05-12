import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chess_ui.dart';
import '../../../models/user_model.dart';
import '../../auth/provider/auth_providers.dart';
import '../../profile/provider/profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      bottomNavigationBar: const ChessBottomNav(currentIndex: 0),
      body: ChessBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(profileProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                _TopBar(
                  onLogout: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 28),
                profileAsync.when(
                  data: (user) => _PlayerHeader(user: user),
                  loading: () => const _LoadingHeader(),
                  error: (error, _) => _ErrorPanel(message: '$error'),
                ),
                const SizedBox(height: 28),
                _HomeActionButton(
                  icon: Icons.bolt_rounded,
                  title: 'Online Oyna',
                  highlighted: true,
                  onTap: () => context.push('/matchmaking'),
                ),
                const SizedBox(height: 12),
                _HomeActionButton(
                  icon: Icons.smart_toy_outlined,
                  title: 'Botla Oyna',
                  onTap: () => context.push('/offline-setup'),
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
  final Future<void> Function() onLogout;

  const _TopBar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.castle_outlined,
          color: AppColors.textPrimary,
          size: 36,
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Cikis Yap',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final UserModel user;

  const _PlayerHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PlayerAvatar(name: user.username, radius: 44),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '${user.elo}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.signal_cellular_alt_rounded,
                    color: AppColors.textSecondary,
                    size: 21,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        PlayerAvatar(name: '...', radius: 44, online: false),
        SizedBox(width: 18),
        Expanded(child: LinearProgressIndicator()),
      ],
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool highlighted;
  final VoidCallback onTap;

  const _HomeActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted ? Colors.white : AppColors.textPrimary;
    return ChessPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      color: highlighted ? AppColors.primary : AppColors.surface,
      border: Border.all(
        color: highlighted ? AppColors.primary : AppColors.divider,
      ),
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
    return ChessPanel(
      onTap: () => context.push('/games'),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Son Durum',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Tumunu Gor',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
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
                    color: AppColors.surfaceStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Icon(
                    Icons.grid_on_rounded,
                    color: AppColors.boardLight,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
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
          const Text(
            'Performans',
            style: TextStyle(
              color: AppColors.textPrimary,
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
    final height = 38.0 + (70.0 * (value / maxValue));
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Container(
          height: 112,
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 34,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
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
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
    return ChessPanel(
      color: AppColors.error.withValues(alpha: 0.12),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      child: Text(
        'Profil yuklenemedi: $message',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
