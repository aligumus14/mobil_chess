namespace ChessApp.Application.DTOs;

public class BestMoveResponseDto
{
    public string BestMove { get; set; } = string.Empty;
    public double Evaluation { get; set; }
    public int MoveTimeMs { get; set; }
    public int? Depth { get; set; }
}
