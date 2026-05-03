using ChessApp.Core.Enums;

namespace ChessApp.Application.DTOs;

public class GameDetailDto
{
    public Guid Id { get; set; }
    public GameType GameType { get; set; }
    public GameResult? Result { get; set; }
    public string PlayerColor { get; set; } = "white";
    public bool PlayerWon { get; set; }
    public string? BotDifficulty { get; set; }
    public string StartFen { get; set; } = string.Empty;
    public string CurrentFen { get; set; } = string.Empty;
    public string? Pgn { get; set; }
    public DateTime StartedAt { get; set; }
    public DateTime? EndedAt { get; set; }
    public List<GameMoveDto> Moves { get; set; } = new();
}

public class GameMoveDto
{
    public int MoveNumber { get; set; }
    public string FromSquare { get; set; } = string.Empty;
    public string ToSquare { get; set; } = string.Empty;
    public string San { get; set; } = string.Empty;
    public string FenAfterMove { get; set; } = string.Empty;
    public DateTime PlayedAt { get; set; }
}
