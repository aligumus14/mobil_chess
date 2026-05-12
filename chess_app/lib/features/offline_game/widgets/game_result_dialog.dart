import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../logic/game_models.dart';

class GameResultDialog extends StatelessWidget {
  final GameResult result;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GameResultDialog({
    super.key,
    required this.result,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final isDraw = result.outcome == GameOutcome.draw;
    final title = isDraw
        ? 'Berabere'
        : result.playerWon
        ? 'Kazandin'
        : 'Kaybettin';
    final color = isDraw
        ? AppColors.textSecondary
        : result.playerWon
        ? AppColors.success
        : AppColors.error;
    final icon = isDraw
        ? Icons.handshake_outlined
        : result.playerWon
        ? Icons.emoji_events_rounded
        : Icons.sentiment_dissatisfied_rounded;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, color: color, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.reason,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExit,
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Ana Sayfa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Tekrar Oyna'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
