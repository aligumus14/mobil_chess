using ChessApp.Core.Enums;

namespace ChessApp.Application.Services;

public interface IGameSessionService
{
    OnlineGameSession CreateSession(
        Guid whiteUserId,
        string whiteUsername,
        int whiteElo,
        Guid blackUserId,
        string blackUsername,
        int blackElo,
        OnlineTimeControl timeControl);

    /// Returns all sessions that are currently in progress (not finished).
    IEnumerable<OnlineGameSession> GetActiveSessions();

    OnlineGameSession? GetSession(Guid gameId);
    OnlineGameSession? GetActiveSessionForUser(Guid userId);

    /// Records a move relayed by the moving player. Server trusts the client-provided
    /// FEN (no anti-cheat by design).
    OnlineGameMove AppendMove(
        Guid gameId,
        Guid playerId,
        string fromSquare,
        string toSquare,
        string san,
        string fenAfterMove);

    bool OfferDraw(Guid gameId, Guid playerId);

    OnlineGameSession AcceptDraw(Guid gameId, Guid playerId);

    void SetConnection(Guid gameId, Guid userId, string? connectionId);

    /// Marks the session as finished. Returns the session snapshot so caller can persist + notify.
    OnlineGameSession? FinishGame(Guid gameId, GameResult result, string reason);

    void RemoveSession(Guid gameId);
}
