namespace ChessApp.Core.Entities;

public class EloHistory
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid GameId { get; set; }
    public int OldElo { get; set; }
    public int NewElo { get; set; }
    public int ChangeAmount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public User User { get; set; } = null!;
    public Game Game { get; set; } = null!;
}
