using ChessApp.Core.Enums;

namespace ChessApp.Application.Services;

public static class EloCalculator
{
    private const int KFactor = 32;

    /// Returns (whiteDelta, blackDelta).
    public static (int WhiteDelta, int BlackDelta) Compute(int whiteElo, int blackElo, GameResult result)
    {
        var expectedWhite = 1.0 / (1.0 + Math.Pow(10, (blackElo - whiteElo) / 400.0));
        var expectedBlack = 1.0 - expectedWhite;

        var (whiteScore, blackScore) = result switch
        {
            GameResult.WhiteWin => (1.0, 0.0),
            GameResult.BlackWin => (0.0, 1.0),
            _ => (0.5, 0.5),
        };

        var whiteDelta = (int)Math.Round(KFactor * (whiteScore - expectedWhite));
        var blackDelta = (int)Math.Round(KFactor * (blackScore - expectedBlack));
        return (whiteDelta, blackDelta);
    }
}
