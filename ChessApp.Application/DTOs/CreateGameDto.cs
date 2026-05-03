using ChessApp.Core.Enums;

namespace ChessApp.Application.DTOs;

public class CreateGameDto
{
    public GameType GameType { get; set; } = GameType.OfflineBot;
    public string PlayerColor { get; set; } = "white"; // "white" or "black"
    public string? BotDifficulty { get; set; } // "easy" | "medium" | "hard"
    public string? TimeControl { get; set; }
    public string? TerminationReason { get; set; }
    public GameResult Result { get; set; }
    public string StartFen { get; set; } = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    public string FinalFen { get; set; } = string.Empty;
    public string Pgn { get; set; } = string.Empty;
    public List<CreateGameMoveDto> Moves { get; set; } = new();
    public DateTime StartedAt { get; set; }
    public DateTime EndedAt { get; set; }
}

public class CreateGameMoveDto
{
    public int MoveNumber { get; set; }
    public string FromSquare { get; set; } = string.Empty;
    public string ToSquare { get; set; } = string.Empty;
    public string San { get; set; } = string.Empty;
    public string FenAfterMove { get; set; } = string.Empty;
}
