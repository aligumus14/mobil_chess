import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/provider/auth_providers.dart';
import '../../profile/provider/profile_provider.dart';
import '../widgets/action_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChessApp',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cikis Yap',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(profileProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            profileAsync.when(
              data: (user) => _HeroCard(
                username: user.username,
                elo: user.elo,
                totalGames: user.totalGames,
              ),
              loading: () => const _HeroCard(
                username: '...',
                elo: 0,
                totalGames: 0,
                isLoading: true,
              ),
              error: (e, _) => Card(
                color: AppColors.error.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text('Hata: $e'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Hizli Baslangic',
              subtitle: 'Oyun modunu sec ve hemen devam et',
            ),
            const SizedBox(height: 12),
            ActionCard(
              icon: Icons.smart_toy_outlined,
              title: 'Stockfish ile Oyna',
              subtitle: 'Modern arayuzde bilgisayara karsi oyna, sure sec ve analize gec.',
              eyebrow: 'OFFLINE',
              onTap: () => context.push('/offline-setup'),
            ),
            const SizedBox(height: 12),
            ActionCard(
              icon: Icons.people_alt_outlined,
              title: 'Online Eslesme',
              subtitle: 'Gercek zamanli rakip bul, puan kazan ve tekrar esles.',
              eyebrow: 'PVP',
              iconColor: AppColors.accentDark,
              onTap: () => context.push('/matchmaking'),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Calisma Alani',
              subtitle: 'Gecmis maclarini ac, analiz et ve performansini izle',
            ),
            const SizedBox(height: 12),
            ActionCard(
              icon: Icons.history_edu_outlined,
              title: 'Oyun Gecmisi',
              subtitle: 'Kayitli maclarini, PGN verilerini ve detay tahtasini gor.',
              eyebrow: 'ARSIV',
              onTap: () => context.push('/games'),
            ),
            const SizedBox(height: 12),
            ActionCard(
              icon: Icons.analytics_outlined,
              title: 'Analiz Merkezi',
              subtitle: 'Stockfish ile hamle kalitesini incele, hatalari filtrele.',
              eyebrow: 'REVIEW',
              iconColor: AppColors.warning,
              onTap: () => context.push('/games'),
            ),
            const SizedBox(height: 12),
            ActionCard(
              icon: Icons.person_outline_rounded,
              title: 'Profil ve Istatistik',
              subtitle: 'ELO, toplam mac ve son performans ozetini incele.',
              eyebrow: 'PROFILE',
              iconColor: AppColors.success,
              onTap: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String username;
  final int elo;
  final int totalGames;
  final bool isLoading;

  const _HeroCard({
    required this.username,
    required this.elo,
    required this.totalGames,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Mobil Chess Platform',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Hos geldin,',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            isLoading ? '...' : username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatCard(label: 'ELO', value: elo.toString()),
              const SizedBox(width: 12),
              _StatCard(label: 'Toplam Mac', value: totalGames.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
