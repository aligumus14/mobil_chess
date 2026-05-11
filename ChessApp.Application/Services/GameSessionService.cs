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
        int blackElo,
        OnlineTimeControl timeControl)
    {
        var gameId = Guid.NewGuid();
        var now = DateTime.UtcNow;
        var (initialSec, incrementSec) = timeControl.ToSpec();
        var initialMs = initialSec * 1000;
        var incrementMs = incrementSec * 1000;
        var session = new OnlineGameSession
        {
            GameId = gameId,
            WhiteUserId = whiteUserId,
            BlackUserId = blackUserId,
            WhiteUsername = whiteUsername,
            BlackUsername = blackUsername,
            WhiteStartElo = whiteElo,
            BlackStartElo = blackElo,
            StartedAt = now,
            TimeControl = timeControl,
            InitialMs = initialMs,
            IncrementMs = incrementMs,
            WhiteRemainingMs = initialMs,
            BlackRemainingMs = initialMs,
            TurnStartedAt = now,
        };

        _sessions[gameId] = session;
        _userToGame[whiteUserId] = gameId;
        _userToGame[blackUserId] = gameId;
        return session;
    }

    public IEnumerable<OnlineGameSession> GetActiveSessions()
        => _sessions.Values.Where(s => !s.Finished);

    public OnlineGameSession? GetSession(Guid gameId)
        => _sessions.TryGetValue(gameId, out var s) ? s : null;

    public OnlineGameSession? GetActiveSessionForUser(Guid userId)
    {
        if (!_userToGame.TryGetValue(userId, out var gameId)) return null;
        if (!_sessions.TryGetValue(gameId, out var s)) return null;
        if (s.Finished)
        {
            // Stale mapping — clean it up so this user can start a new game.
            _userToGame.TryRemove(userId, out _);
            return null;
        }
        return s;
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

        var now = DateTime.UtcNow;
        if (!session.HasStarted && now >= session.StartupDeadlineUtc)
        {
            throw new InvalidOperationException("Oyun baslangic suresi doldu.");
        }

        // Each side's first move is free. The normal clocks start only after
        // both players have made their first move.
        var isFirstMoveForSide = session.Moves.All(m => m.PlayerId != playerId);
        var elapsed = isFirstMoveForSide
            ? 0L
            : (long)Math.Max(0, (now - session.TurnStartedAt).TotalMilliseconds);

        if (movingSide == "white")
        {
            var remaining = session.WhiteRemainingMs - elapsed;
            if (remaining <= 0)
            {
                throw new InvalidOperationException("Suren bitti.");
            }
            session.WhiteRemainingMs = remaining + (isFirstMoveForSide ? 0 : session.IncrementMs);
        }
        else
        {
            var remaining = session.BlackRemainingMs - elapsed;
            if (remaining <= 0)
            {
                throw new InvalidOperationException("Suren bitti.");
            }
            session.BlackRemainingMs = remaining + (isFirstMoveForSide ? 0 : session.IncrementMs);
        }

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
        session.TurnStartedAt = now;
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
        _userToGame.TryRemove(session.WhiteUserId, out _);
        _userToGame.TryRemove(session.BlackUserId, out _);
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
        // Free the user→game mapping immediately so a user cannot be redirected
        // back to a finished session even if RemoveSession runs late.
        _userToGame.TryRemove(session.WhiteUserId, out _);
        _userToGame.TryRemove(session.BlackUserId, out _);
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
