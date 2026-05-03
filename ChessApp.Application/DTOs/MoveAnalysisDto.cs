using ChessApp.Core.Enums;

namespace ChessApp.Application.DTOs;

public class MoveAnalysisDto
{
    public int MoveNumber { get; set; }
    public string San { get; set; } = string.Empty;
    public string FenBeforeMove { get; set; } = string.Empty;
    public string FenAfterMove { get; set; } = string.Empty;
    public string BestMove { get; set; } = string.Empty;
    public string PlayedMove { get; set; } = string.Empty;
    public double Evaluation { get; set; }
    public double CentipawnLoss { get; set; }
    public AnalysisClassification Classification { get; set; }
}
