import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chess_ui.dart';
import '../logic/game_models.dart';
import '../provider/offline_game_controller.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  PlayerColor _color = PlayerColor.random;
  BotDifficulty _difficulty = BotDifficulty.medium;
  GameTimeControl _timeControl = GameTimeControl.blitz5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Botla Oyna'),
      ),
      body: ChessBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
            children: [
              const SectionTitle(title: 'Renk Sec'),
              const SizedBox(height: 14),
              _SegmentedControl<PlayerColor>(
                value: _color,
                options: const [
                  _SegmentOption(
                    value: PlayerColor.white,
                    label: 'Beyaz',
                    icon: Icons.circle,
                  ),
                  _SegmentOption(
                    value: PlayerColor.black,
                    label: 'Siyah',
                    icon: Icons.circle_outlined,
                  ),
                  _SegmentOption(
                    value: PlayerColor.random,
                    label: 'Rastgele',
                    icon: Icons.shuffle_rounded,
                  ),
                ],
                onChanged: (value) => setState(() => _color = value),
              ),
              const SizedBox(height: 34),
              const SectionTitle(title: 'Zorluk'),
              const SizedBox(height: 14),
              _SegmentedControl<BotDifficulty>(
                value: _difficulty,
                options: BotDifficulty.values
                    .map(
                      (item) => _SegmentOption(value: item, label: item.label),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _difficulty = value),
              ),
              const SizedBox(height: 34),
              const SectionTitle(title: 'Tempo'),
              const SizedBox(height: 14),
              _SegmentedControl<GameTimeControl>(
                value: _timeControl,
                options: GameTimeControl.values
                    .map(
                      (item) =>
                          _SegmentOption(value: item, label: _timeLabel(item)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _timeControl = value),
              ),
              const SizedBox(height: 34),
              _BotSummary(difficulty: _difficulty, timeControl: _timeControl),
              const SizedBox(height: 44),
              FilledButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.sports_martial_arts_rounded),
                label: const Text('Oyunu Baslat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeLabel(GameTimeControl value) {
    return switch (value) {
      GameTimeControl.unlimited => 'Suresiz',
      GameTimeControl.blitz5 => '5+0',
      GameTimeControl.rapid10 => '10+0',
    };
  }

  void _startGame() {
    ref
        .read(offlineGameProvider.notifier)
        .startNewGame(
          GameSettings(
            playerColor: _color,
            difficulty: _difficulty,
            timeControl: _timeControl,
          ),
        );
    context.push('/offline-game');
  }
}

class _BotSummary extends StatelessWidget {
  final BotDifficulty difficulty;
  final GameTimeControl timeControl;

  const _BotSummary({required this.difficulty, required this.timeControl});

  @override
  Widget build(BuildContext context) {
    return ChessPanel(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppColors.textPrimary,
              size: 48,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.smart_toy_outlined,
                  label: 'Rakip:',
                  value: 'Stockfish',
                ),
                const Divider(height: 22),
                _SummaryRow(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: 'Seviye:',
                  value: difficulty.label,
                  accent: true,
                ),
                const Divider(height: 22),
                _SummaryRow(
                  icon: Icons.schedule_rounded,
                  label: 'Tempo:',
                  value: GameSetupScreenLabel.timeLabel(timeControl),
                  accent: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameSetupScreenLabel {
  static String timeLabel(GameTimeControl value) {
    return switch (value) {
      GameTimeControl.unlimited => 'Suresiz',
      GameTimeControl.blitz5 => '5+0',
      GameTimeControl.rapid10 => '10+0',
    };
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool accent;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent ? AppColors.primary : AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const _SegmentOption({required this.value, required this.label, this.icon});
}

class _SegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<_SegmentOption<T>> options;
  final ValueChanged<T> onChanged;

  const _SegmentedControl({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 44, color: AppColors.divider),
            Expanded(
              child: _SegmentButton<T>(
                option: options[i],
                selected: options[i].value == value,
                onTap: () => onChanged(options[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  final _SegmentOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Colors.transparent;
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, color: foreground, size: 22),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
