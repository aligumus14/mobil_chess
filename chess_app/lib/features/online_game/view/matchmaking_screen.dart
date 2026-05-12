import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chess_ui.dart';
import '../../../services/matchmaking_service.dart';
import '../../auth/provider/auth_providers.dart';
import '../logic/online_time_control.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  OnlineTimeControl _selectedTempo = OnlineTimeControl.blitz5;
  bool _busy = false;
  bool _inQueue = false;
  Timer? _pollTimer;
  String? _error;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _join() async {
    if (_busy || _inQueue) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = ref.read(matchmakingServiceProvider);
      final result = await service.join(timeControl: _selectedTempo);
      if (!mounted) return;

      if (result.matched && result.gameId != null) {
        _goToGame(result);
        return;
      }

      setState(() {
        _inQueue = true;
        _busy = false;
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Eslesme basarisiz: $e';
        _busy = false;
        _inQueue = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || !_inQueue) return;
    try {
      final service = ref.read(matchmakingServiceProvider);
      final status = await service.status();
      if (!mounted) return;
      if (status.activeGameId != null) {
        _pollTimer?.cancel();
        final joinResult = JoinQueueResult(
          matched: true,
          gameId: status.activeGameId,
          assignedColor: null,
          startFen: null,
        );
        _goToGame(joinResult);
        return;
      }
      if (!status.inQueue) {
        final result = await service.join(timeControl: _selectedTempo);
        if (!mounted) return;
        if (result.matched && result.gameId != null) {
          _pollTimer?.cancel();
          _goToGame(result);
        }
      }
    } catch (_) {}
  }

  Future<void> _leave() async {
    _pollTimer?.cancel();
    try {
      await ref.read(matchmakingServiceProvider).leave();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _inQueue = false;
        _busy = false;
      });
    }
  }

  void _goToGame(JoinQueueResult result) {
    context.pushReplacement('/online-game/${result.gameId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.textPrimary,
            ),
            SizedBox(width: 8),
            Text('Online Eslesme'),
          ],
        ),
      ),
      bottomNavigationBar: const ChessBottomNav(currentIndex: 0),
      body: ChessBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            children: [
              ..._buildTempoSections(),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy || _inQueue ? null : _join,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text('${_selectedTempo.label} ile esles'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                ChessPanel(
                  color: AppColors.error.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
              if (_inQueue) ...[
                const SizedBox(height: 22),
                _QueueCard(tempo: _selectedTempo, onCancel: _leave),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTempoSections() {
    final groups = <String, List<OnlineTimeControl>>{};
    for (final tc in OnlineTimeControl.values) {
      groups.putIfAbsent(tc.category, () => []).add(tc);
    }

    final children = <Widget>[];
    for (final entry in groups.entries) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 26));
        children.add(const Divider(height: 1));
        children.add(const SizedBox(height: 26));
      }

      children.add(
        SectionTitle(title: entry.key, icon: _categoryIcon(entry.key)),
      );
      children.add(const SizedBox(height: 14));
      children.add(
        _TempoGrid(
          tempos: entry.value,
          selectedTempo: _selectedTempo,
          enabled: !_inQueue && !_busy,
          onSelected: (tempo) => setState(() => _selectedTempo = tempo),
        ),
      );
    }
    return children;
  }

  IconData _categoryIcon(String category) {
    return switch (category) {
      'Blitz' => Icons.bolt_rounded,
      'Rapid' => Icons.timer_outlined,
      _ => Icons.military_tech_outlined,
    };
  }
}

class _TempoGrid extends StatelessWidget {
  final List<OnlineTimeControl> tempos;
  final OnlineTimeControl selectedTempo;
  final bool enabled;
  final ValueChanged<OnlineTimeControl> onSelected;

  const _TempoGrid({
    required this.tempos,
    required this.selectedTempo,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tempos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.78,
      ),
      itemBuilder: (context, index) {
        final tempo = tempos[index];
        return _TempoCard(
          tempo: tempo,
          selected: selectedTempo == tempo,
          enabled: enabled,
          onTap: () => onSelected(tempo),
        );
      },
    );
  }
}

class _TempoCard extends StatelessWidget {
  final OnlineTimeControl tempo;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _TempoCard({
    required this.tempo,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.surface;
    final textColor = selected ? Colors.white : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            tempo.label,
            style: TextStyle(
              color: textColor,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final OnlineTimeControl tempo;
  final VoidCallback onCancel;

  const _QueueCard({required this.tempo, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return ChessPanel(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 7,
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceStrong,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rakip araniyor',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tempo.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onCancel, child: const Text('Iptal')),
        ],
      ),
    );
  }
}
