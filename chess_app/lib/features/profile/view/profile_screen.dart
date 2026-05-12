import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chess_ui.dart';
import '../../../models/user_model.dart';
import '../provider/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      bottomNavigationBar: const ChessBottomNav(currentIndex: 2),
      body: ChessBackground(
        child: SafeArea(
          child: profileAsync.when(
            data: (user) => _ProfileBody(user: user),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ProfileError(
              message: '$e',
              onRetry: () => ref.invalidate(profileProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final UserModel user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      children: [
        const _ProfileTopBar(),
        const SizedBox(height: 34),
        _ProfileHeader(user: user),
        const SizedBox(height: 28),
        _RecordPanel(user: user),
        const SizedBox(height: 28),
        const SectionTitle(title: 'Puanlarim'),
        const SizedBox(height: 14),
        _RatingCards(user: user),
        const SizedBox(height: 22),
        _RatingPanel(user: user),
        const SizedBox(height: 28),
        const SectionTitle(title: 'Hesap'),
        const SizedBox(height: 14),
        ChessPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.person_outline_rounded,
                title: 'Hesap Ayarlari',
                value: user.email,
              ),
              const Divider(height: 1),
              const _SettingRow(
                icon: Icons.palette_outlined,
                title: 'Tema',
                value: 'Koyu',
              ),
              const Divider(height: 1),
              const _SettingRow(
                icon: Icons.notifications_none_rounded,
                title: 'Bildirimler',
                value: 'Acik',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.castle_outlined, color: AppColors.textPrimary, size: 34),
        Expanded(
          child: Center(
            child: Text(
              'Profil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textPrimary,
          size: 30,
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PlayerAvatar(name: user.username, radius: 54),
        const SizedBox(width: 22),
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
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${user.elo}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.signal_cellular_alt_rounded,
                    color: AppColors.textSecondary,
                    size: 24,
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

class _RecordPanel extends StatelessWidget {
  final UserModel user;

  const _RecordPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return ChessPanel(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: [
          Expanded(
            child: MetricTile(
              icon: Icons.trip_origin_rounded,
              label: 'Galibiyet',
              value: '${user.wins}',
              color: AppColors.primary,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: MetricTile(
              icon: Icons.close_rounded,
              label: 'Maglubiyet',
              value: '${user.losses}',
              color: AppColors.error,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: MetricTile(
              icon: Icons.drag_handle_rounded,
              label: 'Beraberlik',
              value: '${user.draws}',
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCards extends StatelessWidget {
  final UserModel user;

  const _RatingCards({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RatingCard(
            icon: Icons.bolt_rounded,
            label: 'Blitz',
            value: user.elo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RatingCard(
            icon: Icons.timer_outlined,
            label: 'Rapid',
            value: user.elo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RatingCard(
            icon: Icons.military_tech_outlined,
            label: 'Classical',
            value: user.elo,
          ),
        ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _RatingCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ChessPanel(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 30),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPanel extends StatelessWidget {
  final UserModel user;

  const _RatingPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return ChessPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Puan Ozeti',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.trending_up_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${user.winRate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 138,
            width: double.infinity,
            child: CustomPaint(
              painter: _RatingPainter(
                elo: user.elo,
                wins: user.wins,
                losses: user.losses,
                draws: user.draws,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Oyunlar', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                'Galibiyet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text('Puan', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingPainter extends CustomPainter {
  final int elo;
  final int wins;
  final int losses;
  final int draws;

  const _RatingPainter({
    required this.elo,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final total = (wins + losses + draws).clamp(1, 9999);
    final momentum = ((wins - losses) / total).clamp(-0.35, 0.35);
    final points = List.generate(6, (index) {
      final t = index / 5;
      final wave = (index.isEven ? 0.08 : -0.05);
      final yFactor = (0.62 - momentum * t + wave).clamp(0.18, 0.82);
      return Offset(size.width * t, size.height * yFactor);
    });

    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.32),
          AppColors.primary.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = AppColors.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$elo',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width, 0));
  }

  @override
  bool shouldRepaint(covariant _RatingPainter oldDelegate) {
    return oldDelegate.elo != elo ||
        oldDelegate.wins != wins ||
        oldDelegate.losses != losses ||
        oldDelegate.draws != draws;
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 86, color: AppColors.divider);
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ChessPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Profil yuklenemedi\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
