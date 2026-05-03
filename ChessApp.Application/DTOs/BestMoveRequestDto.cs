namespace ChessApp.Application.DTOs;

public class BestMoveRequestDto
{
    public string Fen { get; set; } = string.Empty;
    public string? Difficulty { get; set; }
    public int? MoveTimeMs { get; set; }
    public int? Depth { get; set; }
}
