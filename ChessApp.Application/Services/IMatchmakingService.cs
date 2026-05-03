using ChessApp.Application.DTOs;

namespace ChessApp.Application.Services;

public interface IMatchmakingService
{
    Task<JoinQueueResultDto> JoinQueueAsync(Guid userId);
    Task<bool> LeaveQueueAsync(Guid userId);
    Task<MatchmakingStatusDto> GetStatusAsync(Guid userId);
}
