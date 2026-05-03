import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MoveListPanel extends StatelessWidget {
  final List<String> moves;

  const MoveListPanel({
    super.key,
    required this.moves,
  });

  @override
  Widget build(BuildContext context) {
    final pairs = <({int num, String white, String? black})>[];
    for (var i = 0; i < moves.length; i += 2) {
      pairs.add((
        num: (i ~/ 2) + 1,
        white: moves[i],
        black: i + 1 < moves.length ? moves[i + 1] : null,
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_list_numbered_rounded, color: AppColors.textPrimary),
                SizedBox(width: 10),
                Text(
                  'Hamle Akisi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (pairs.isEmpty)
              const Text(
                'Henuz hamle yok.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 230),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pairs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final pair = pairs[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${pair.num}.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              pair.white,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              pair.black ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
