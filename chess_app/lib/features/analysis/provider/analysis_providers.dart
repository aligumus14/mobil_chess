import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/game_models.dart';
import '../../auth/provider/auth_providers.dart';

final gameAnalysisProvider =
    FutureProvider.autoDispose.family<GameAnalysis, String>((ref, gameId) {
      final service = ref.watch(analysisServiceProvider);
      return service.analyzeGame(gameId);
    });
