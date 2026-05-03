using System.Collections.Concurrent;
using ChessApp.Core.Enums;

namespace ChessApp.Application.Services;

public class GameSessionService : IGameSessionService
{
    private readonly ConcurrentDictionary<Guid, OnlineGameSession> _sessions = new();
    private readonly ConcurrentDictionary<Guid, Guid> _userToGame = new();

    public OnlineGameSession CreateSession(
        Guid whiteUserId,
        string whiteUsername,
        int whiteElo,
        Guid blackUserId,
        string blackUsername,
        int blackElo)
    {
        var gameId = Guid.NewGuid();
        var session = new OnlineGameSession
        {
            GameId = gameId,
            WhiteUserId = whiteUserId,
            BlackUserId = blackUserId,
            WhiteUsername = whiteUsername,
            BlackUsername = blackUsername,
            WhiteStartElo = whiteElo,
            BlackStartElo = blackElo,
        };

        _sessions[gameId] = session;
        _userToGame[whiteUserId] = gameId;
        _userToGame[blackUserId] = gameId;
        return session;
    }

    public OnlineGameSession? GetSession(Guid gameId)
        => _sessions.TryGetValue(gameId, out var s) ? s : null;

    public OnlineGameSession? GetActiveSessionForUser(Guid userId)
    {
        if (!_userToGame.TryGetValue(userId, out var gameId)) return null;
        return _sessions.TryGetValue(gameId, out var s) ? s : null;
    }

    public OnlineGameMove AppendMove(
        Guid gameId,
        Guid playerId,
        string fromSquare,
        string toSquare,
        string san,
        string fenAfterMove)
    {
        if (!_sessions.TryGetValue(gameId, out var session))
            throw new InvalidOperationException("Oyun bulunamadi.");

        if (!session.IsParticipant(playerId))
            throw new InvalidOperationException("Bu oyunun katilimcisi degilsin.");

        if (session.Finished)
            throw new InvalidOperationException("Oyun zaten bitmis.");

        var movingSide = session.SideOf(playerId);
        if (movingSide != session.CurrentTurn)
            throw new InvalidOperationException("Sira sende degil.");

        var move = new OnlineGameMove
        {
            MoveNumber = session.Moves.Count + 1,
            PlayerId = playerId,
            FromSquare = fromSquare,
            ToSquare = toSquare,
            San = san,
            FenAfterMove = fenAfterMove,
        };

        session.Moves.Add(move);
        session.CurrentFen = fenAfterMove;
        session.CurrentTurn = session.CurrentTurn == "white" ? "black" : "white";
        session.PendingDrawOfferByUserId = null;
        return move;
    }

    public bool OfferDraw(Guid gameId, Guid playerId)
    {
        if (!_sessions.TryGetValue(gameId, out var session))
            throw new InvalidOperationException("Oyun bulunamadi.");

        if (!session.IsParticipant(playerId))
            throw new InvalidOperationException("Bu oyunun katilimcisi degilsin.");

        if (session.Finished)
            throw new InvalidOperationException("Oyun zaten bitmis.");

        if (session.PendingDrawOfferByUserId == playerId)
            return false;

        session.PendingDrawOfferByUserId = playerId;
        return true;
    }

    public OnlineGameSession AcceptDraw(Guid gameId, Guid playerId)
    {
        if (!_sessions.TryGetValue(gameId, out var session))
            throw new InvalidOperationException("Oyun bulunamadi.");

        if (!session.IsParticipant(playerId))
            throw new InvalidOperationException("Bu oyunun katilimcisi degilsin.");

        if (session.Finished)
            throw new InvalidOperationException("Oyun zaten bitmis.");

        if (session.PendingDrawOfferByUserId is null)
            throw new InvalidOperationException("Bekleyen beraberlik teklifi yok.");

        if (session.PendingDrawOfferByUserId == playerId)
            throw new InvalidOperationException("Kendi teklifini kabul edemezsin.");

        session.PendingDrawOfferByUserId = null;
        session.Result = GameResult.Draw;
        session.TerminationReason = "draw-agreed";
        return session;
    }

    public void SetConnection(Guid gameId, Guid userId, string? connectionId)
    {
        if (!_sessions.TryGetValue(gameId, out var session)) return;
        if (userId == session.WhiteUserId)
            session.WhiteConnectionId = connectionId;
        else if (userId == session.BlackUserId)
            session.BlackConnectionId = connectionId;
    }

    public OnlineGameSession? FinishGame(Guid gameId, GameResult result, string reason)
    {
        if (!_sessions.TryGetValue(gameId, out var session)) return null;
        if (session.Finished) return session;
        session.PendingDrawOfferByUserId = null;
        session.Result = result;
        session.TerminationReason = reason;
        return session;
    }

    public void RemoveSession(Guid gameId)
    {
        if (_sessions.TryRemove(gameId, out var session))
        {
            _userToGame.TryRemove(session.WhiteUserId, out _);
            _userToGame.TryRemove(session.BlackUserId, out _);
        }
    }
}
