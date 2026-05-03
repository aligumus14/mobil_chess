import 'package:chess/chess.dart' as ch;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../provider/offline_game_controller.dart';

class StatusBar extends StatelessWidget {
  final OfflineGameState state;

  const StatusBar({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final label = _label();
    final color = _color();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.settings.timeControl.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (state.botThinking)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
              ),
            ),
        ],
      ),
    );
  }

  IconData _icon() {
    if (state.isGameOver) {
      return Icons.flag_rounded;
    }
    if (state.botThinking) {
      return Icons.psychology_alt_rounded;
    }
    return state.isPlayerTurn ? Icons.touch_app_rounded : Icons.smart_toy_outlined;
  }

  Color _color() {
    if (state.isGameOver) {
      return AppColors.textSecondary;
    }
    return state.isPlayerTurn ? AppColors.primary : AppColors.accentDark;
  }

  String _label() {
    if (state.result != null) {
      return 'Oyun bitti - ${state.result!.reason}';
    }
    if (state.botThinking) {
      return 'Stockfish dusunuyor';
    }
    final side = state.playerSide == ch.Color.WHITE ? 'Beyaz' : 'Siyah';
    return state.isPlayerTurn ? 'Sira sende ($side)' : 'Sira rakipte';
  }
}
