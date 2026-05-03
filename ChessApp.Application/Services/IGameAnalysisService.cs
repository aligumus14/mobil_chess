using ChessApp.Application.DTOs;

namespace ChessApp.Application.Services;

public interface IGameAnalysisService
{
    Task<GameAnalysisDto?> GetGameAnalysisAsync(Guid gameId, Guid userId);
    Task<GameAnalysisDto> AnalyzeGameAsync(Guid gameId, Guid userId, bool force = false);
}
