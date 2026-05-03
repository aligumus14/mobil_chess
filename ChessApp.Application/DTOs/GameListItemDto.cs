using ChessApp.Core.Enums;

namespace ChessApp.Application.DTOs;

public class GameListItemDto
{
    public Guid Id { get; set; }
    public GameType GameType { get; set; }
    public GameResult? Result { get; set; }
    public string PlayerColor { get; set; } = "white";
    public bool PlayerWon { get; set; }
    public string? BotDifficulty { get; set; }
    public int MoveCount { get; set; }
    public DateTime StartedAt { get; set; }
    public DateTime? EndedAt { get; set; }
}
