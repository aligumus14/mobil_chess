using ChessApp.Core.Enums;

namespace ChessApp.Core.Entities;

public class Game
{
    public Guid Id { get; set; }
    public Guid WhitePlayerId { get; set; }
    public Guid BlackPlayerId { get; set; }
    public GameType GameType { get; set; }
    public GameStatus Status { get; set; } = GameStatus.Waiting;
    public GameResult? Result { get; set; }
    public string StartFen { get; set; } = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    public string CurrentFen { get; set; } = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    public string? Pgn { get; set; }
    public Guid? WinnerUserId { get; set; }
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime? EndedAt { get; set; }

    // Navigation properties
    public User WhitePlayer { get; set; } = null!;
    public User BlackPlayer { get; set; } = null!;
    public User? Winner { get; set; }
    public ICollection<GameMove> Moves { get; set; } = new List<GameMove>();
    public ICollection<AnalysisResult> AnalysisResults { get; set; } = new List<AnalysisResult>();
    public ICollection<EloHistory> EloHistories { get; set; } = new List<EloHistory>();
}
