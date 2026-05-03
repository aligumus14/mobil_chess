using ChessApp.Core.Enums;

namespace ChessApp.Application.DTOs;

public class GameAnalysisDto
{
    public Guid GameId { get; set; }
    public GameResult? Result { get; set; }
    public int MoveCount { get; set; }
    public List<MoveAnalysisDto> Moves { get; set; } = new();
}
