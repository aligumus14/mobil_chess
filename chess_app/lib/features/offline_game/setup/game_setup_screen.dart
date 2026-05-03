import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../logic/game_models.dart';
import '../provider/offline_game_controller.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  PlayerColor _color = PlayerColor.white;
  BotDifficulty _difficulty = BotDifficulty.medium;
  GameTimeControl _timeControl = GameTimeControl.unlimited;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Oyun Kurulumu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stockfish Arena',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Renkini, zorlugu ve sure formatini sec. Ardindan modern oyun ekraninda dogrudan maca basla.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Renk Secimi',
            subtitle: 'Beyaz, siyah veya rastgele baslangic',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _colorTile(PlayerColor.white, 'Beyaz', Icons.circle_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _colorTile(PlayerColor.black, 'Siyah', Icons.circle)),
              const SizedBox(width: 10),
              Expanded(child: _colorTile(PlayerColor.random, 'Rastgele', Icons.shuffle_rounded)),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Zorluk Seviyesi',
            subtitle: 'Stockfish dusunme suresi burada belirlenir',
          ),
          const SizedBox(height: 10),
          ...BotDifficulty.values.map(_difficultyTile),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Sure Formati',
            subtitle: 'Sureli veya limitsiz oyun sec',
          ),
          const SizedBox(height: 10),
          ...GameTimeControl.values.map(_timeTile),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Maci Baslat'),
          ),
        ],
      ),
    );
  }

  Widget _colorTile(PlayerColor value, String label, IconData icon) {
    final selected = _color == value;
    return InkWell(
      onTap: () => setState(() => _color = value),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _difficultyTile(BotDifficulty value) {
    final selected = _difficulty == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _difficulty = value),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceStrong : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              _SelectionIndicator(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeTile(GameTimeControl value) {
    final selected = _timeControl == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _timeControl = value),
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceStrong : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.accentDark : AppColors.divider,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              _SelectionIndicator(
                selected: selected,
                color: AppColors.accentDark,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame() {
    ref.read(offlineGameProvider.notifier).startNewGame(
      GameSettings(
        playerColor: _color,
        difficulty: _difficulty,
        timeControl: _timeControl,
      ),
    );
    context.push('/offline-game');
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
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
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool selected;
  final Color color;

  const _SelectionIndicator({
    required this.selected,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? color : AppColors.divider,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}
