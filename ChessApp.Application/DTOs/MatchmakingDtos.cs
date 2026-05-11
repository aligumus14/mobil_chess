namespace ChessApp.Application.DTOs;

public class MatchmakingStatusDto
{
    public bool InQueue { get; set; }
    public DateTime? QueuedAt { get; set; }
    public int? EloSnapshot { get; set; }
    public Guid? ActiveGameId { get; set; }
}

public class JoinQueueRequestDto
{
    /// OnlineTimeControl enum value (0..8). See ChessApp.Core.Enums.OnlineTimeControl.
    public int TimeControl { get; set; }
}

public class JoinQueueResultDto
{
    public bool Matched { get; set; }
    public bool Resumed { get; set; }
    public Guid? GameId { get; set; }
    public Guid? OpponentId { get; set; }
    public string? OpponentUsername { get; set; }
    public int? OpponentElo { get; set; }
    public string? AssignedColor { get; set; } // "white" | "black"
    public string? StartFen { get; set; }
    public int? TimeControl { get; set; }
    public int? InitialSeconds { get; set; }
    public int? IncrementSeconds { get; set; }
}
