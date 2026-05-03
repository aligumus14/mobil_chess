using ChessApp.Core.Enums;

namespace ChessApp.Core.Entities;

public class MatchQueue
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public int EloSnapshot { get; set; }
    public DateTime QueuedAt { get; set; } = DateTime.UtcNow;
    public MatchQueueStatus Status { get; set; } = MatchQueueStatus.Waiting;

    // Navigation properties
    public User User { get; set; } = null!;
}
