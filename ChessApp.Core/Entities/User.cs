namespace ChessApp.Core.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public int Elo { get; set; } = 1000;
    public int Wins { get; set; }
    public int Losses { get; set; }
    public int Draws { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<Game> WhiteGames { get; set; } = new List<Game>();
    public ICollection<Game> BlackGames { get; set; } = new List<Game>();
    public ICollection<EloHistory> EloHistories { get; set; } = new List<EloHistory>();
    public ICollection<GameMove> Moves { get; set; } = new List<GameMove>();
}
