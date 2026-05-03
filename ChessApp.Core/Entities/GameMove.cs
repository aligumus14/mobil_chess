namespace ChessApp.Core.Entities;

public class GameMove
{
    public Guid Id { get; set; }
    public Guid GameId { get; set; }
    public int MoveNumber { get; set; }
    public Guid PlayerId { get; set; }
    public string FromSquare { get; set; } = string.Empty;
    public string ToSquare { get; set; } = string.Empty;
    public string San { get; set; } = string.Empty;
    public string FenAfterMove { get; set; } = string.Empty;
    public DateTime PlayedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Game Game { get; set; } = null!;
    public User Player { get; set; } = null!;
}
