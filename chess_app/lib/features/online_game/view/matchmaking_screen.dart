import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/matchmaking_service.dart';
import '../../auth/provider/auth_providers.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  bool _busy = false;
  bool _inQueue = false;
  Timer? _pollTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

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
      final result = await service.join();
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
        final result = await service.join();
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
    if (mounted) context.pop();
  }

  void _goToGame(JoinQueueResult result) {
    context.pushReplacement('/online-game/${result.gameId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eslesme')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _join,
                  child: const Text('Tekrar Dene'),
                ),
              ] else if (_inQueue) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Rakip araniyor...',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Benzer ELO\'ya sahip bir oyuncu bulundugunda baslar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _leave,
                  icon: const Icon(Icons.close),
                  label: const Text('Iptal'),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text('Siraya giriliyor...'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
