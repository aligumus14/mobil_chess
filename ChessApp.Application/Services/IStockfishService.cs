namespace ChessApp.Application.Services;

public interface IStockfishService : IDisposable
{
    Task<StockfishAnalysisResult> AnalyzePositionAsync(
        string fen,
        int? depth = null,
        CancellationToken cancellationToken = default);

    Task<StockfishAnalysisResult> GetBestMoveAsync(
        string fen,
        int? moveTimeMs = null,
        int? depth = null,
        CancellationToken cancellationToken = default);
}
