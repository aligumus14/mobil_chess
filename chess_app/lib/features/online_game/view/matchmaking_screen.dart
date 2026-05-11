import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (_busy) return;
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
      appBar: AppBar(title: const Text('Online Eslesme')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _inQueue ? _buildQueueing() : _buildPicker(),
        ),
      ),
    );
  }

  Widget _buildPicker() {
    final groups = <String, List<OnlineTimeControl>>{};
    for (final tc in OnlineTimeControl.values) {
      groups.putIfAbsent(tc.category, () => []).add(tc);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tempo Sec',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sectigin tempoda baska bir oyuncuyla eslesirsin.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: [
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: entry.value
                      .map((tc) => _TempoChip(
                            tempo: tc,
                            selected: _selectedTempo == tc,
                            onTap: () => setState(() => _selectedTempo = tc),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _busy ? null : _join,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('${_selectedTempo.label} ile Esles'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueing() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            '${_selectedTempo.label} icin rakip araniyor...',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ayni tempoyu secen oyuncular ELO yakinligina gore oncelikli eslesir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _leave,
            icon: const Icon(Icons.close),
            label: const Text('Iptal'),
          ),
        ],
      ),
    );
  }
}

class _TempoChip extends StatelessWidget {
  final OnlineTimeControl tempo;
  final bool selected;
  final VoidCallback onTap;

  const _TempoChip({
    required this.tempo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          tempo.label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
