namespace ChessApp.Application.Services;

public sealed class StockfishAnalysisResult
{
    public string BestMove { get; init; } = string.Empty;
    public double EvaluationCp { get; init; }
}
