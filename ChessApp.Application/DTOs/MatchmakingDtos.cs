namespace ChessApp.Application.DTOs;

public class MatchmakingStatusDto
{
    public bool InQueue { get; set; }
    public DateTime? QueuedAt { get; set; }
    public int? EloSnapshot { get; set; }
    public Guid? ActiveGameId { get; set; }
}

public class JoinQueueResultDto
{
    public bool Matched { get; set; }
    public Guid? GameId { get; set; }
    public Guid? OpponentId { get; set; }
    public string? OpponentUsername { get; set; }
    public int? OpponentElo { get; set; }
    public string? AssignedColor { get; set; } // "white" | "black"
    public string? StartFen { get; set; }
}
