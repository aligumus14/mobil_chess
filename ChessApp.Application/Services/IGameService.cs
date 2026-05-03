using ChessApp.Application.DTOs;

namespace ChessApp.Application.Services;

public interface IGameService
{
    Task<Guid> CreateOfflineGameAsync(Guid userId, CreateGameDto dto);
    Task<PagedResultDto<GameListItemDto>> GetUserGamesAsync(Guid userId, int page, int pageSize);
    Task<GameDetailDto?> GetGameDetailAsync(Guid gameId, Guid userId);

    /// Persists a finished online session and applies ELO updates to both users.
    /// Returns (whiteDelta, blackDelta) so caller can notify clients.
    Task<(int WhiteDelta, int BlackDelta)> PersistOnlineSessionAsync(OnlineGameSession session);
}
