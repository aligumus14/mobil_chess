using ChessApp.Core.Enums;

namespace ChessApp.Core.Entities;

public class AnalysisResult
{
    public Guid Id { get; set; }
    public Guid GameId { get; set; }
    public int MoveNumber { get; set; }
    public string BestMove { get; set; } = string.Empty;
    public string PlayedMove { get; set; } = string.Empty;
    public double Evaluation { get; set; }
    public AnalysisClassification Classification { get; set; }

    // Navigation properties
    public Game Game { get; set; } = null!;
}
