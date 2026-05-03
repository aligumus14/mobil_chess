import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/game_models.dart';
import '../../auth/provider/auth_providers.dart';

class GameHistoryPageRequest {
  final int page;
  final int pageSize;

  const GameHistoryPageRequest({
    required this.page,
    required this.pageSize,
  });

  @override
  bool operator ==(Object other) {
    return other is GameHistoryPageRequest &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(page, pageSize);
}

final myGamesProvider = FutureProvider.autoDispose
    .family<PagedGames, GameHistoryPageRequest>((ref, request) {
  final service = ref.watch(gameHistoryServiceProvider);
  return service.getMyGames(page: request.page, pageSize: request.pageSize);
});

final gameDetailProvider =
    FutureProvider.autoDispose.family<GameDetail, String>((ref, gameId) {
  final service = ref.watch(gameHistoryServiceProvider);
  return service.getGameById(gameId);
});
