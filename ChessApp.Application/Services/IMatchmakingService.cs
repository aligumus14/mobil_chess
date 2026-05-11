using ChessApp.Application.DTOs;
using ChessApp.Core.Enums;

namespace ChessApp.Application.Services;

public interface IMatchmakingService
{
    Task<JoinQueueResultDto> JoinQueueAsync(Guid userId, OnlineTimeControl timeControl);
    Task<bool> LeaveQueueAsync(Guid userId);
    Task<MatchmakingStatusDto> GetStatusAsync(Guid userId);

    /// Forfeits any in-memory active session for this user (counts as resign for them).
    /// Persists the game with ELO/stat updates and removes the session. Returns true
    /// if a session was abandoned.
    Task<bool> AbandonActiveSessionAsync(Guid userId);
}
