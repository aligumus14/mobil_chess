using ChessApp.Application.DTOs;
using ChessApp.Core.Enums;
using ChessApp.Core.Interfaces;

namespace ChessApp.Application.Services;

public class MatchmakingService : IMatchmakingService
{
    private static readonly SemaphoreSlim _queueLock = new(1, 1);

    private readonly IUnitOfWork _unitOfWork;
    private readonly IGameSessionService _sessionService;
    private readonly IGameService _gameService;

    public MatchmakingService(
        IUnitOfWork unitOfWork,
        IGameSessionService sessionService,
        IGameService gameService)
    {
        _unitOfWork = unitOfWork;
        _sessionService = sessionService;
        _gameService = gameService;
    }

    public async Task<JoinQueueResultDto> JoinQueueAsync(Guid userId, OnlineTimeControl timeControl)
    {
        await _queueLock.WaitAsync();
        try
        {
            Console.WriteLine($"[Matchmaking] Join userId={userId} tempo={timeControl}");

            // Only treat a leftover session as something to abandon if it has been
            // played at least one move or already finished. A session that exists
            // but has no moves is brand-new (just created for a freshly-matched
            // opponent), and we must not nuke it — otherwise the polling user
            // races with the freshly-matched session and tears it down before the
            // other side has joined.
            var leftover = _sessionService.GetActiveSessionForUser(userId);
            if (leftover != null && (leftover.Finished || leftover.Moves.Count > 0))
            {
                if (!leftover.Finished)
                {
                    var abandoningSide = leftover.SideOf(userId);
                    var result = abandoningSide == "white" ? GameResult.BlackWin : GameResult.WhiteWin;
                    _sessionService.FinishGame(leftover.GameId, result, "abandoned");
                    try
                    {
                        await _gameService.PersistOnlineSessionAsync(leftover);
                    }
                    catch
                    {
                        // Persistence is best-effort; we still want to free the slot.
                    }
                }
                _sessionService.RemoveSession(leftover.GameId);
                Console.WriteLine($"[Matchmaking]   cleared leftover session for {userId}");
            }
            else if (leftover != null)
            {
                // Brand-new session waiting for both sides to join — return it
                // as the match so the polling client lands in the right game.
                Console.WriteLine($"[Matchmaking]   user already in fresh session {leftover.GameId}");
                return BuildMatchedResult(leftover, userId, resumed: true);
            }

            var user = await _unitOfWork.Users.GetByIdAsync(userId)
                ?? throw new InvalidOperationException("Kullanici bulunamadi.");

            // Only consider candidates that requested the same time control. Players
            // who picked 5+0 never match against players who picked 10+2, etc.
            var waiting = (await _unitOfWork.MatchQueues.FindAsync(
                q => q.Status == MatchQueueStatus.Waiting
                    && q.UserId != userId
                    && q.TimeControl == timeControl))
                .OrderBy(q => Math.Abs(q.EloSnapshot - user.Elo))
                .ThenBy(q => q.QueuedAt)
                .ToList();

            Console.WriteLine($"[Matchmaking]   {waiting.Count} waiting candidates with same tempo");

            // ELO is an ordering preference, not a hard blocker. With a small
            // online pool, a strict cutoff can leave two same-tempo players
            // waiting forever.
            var candidate = waiting.FirstOrDefault();

            if (candidate == null)
            {
                var existing = await _unitOfWork.MatchQueues.FirstOrDefaultAsync(q => q.UserId == userId);
                if (existing != null)
                {
                    existing.Status = MatchQueueStatus.Waiting;
                    existing.EloSnapshot = user.Elo;
                    existing.QueuedAt = DateTime.UtcNow;
                    existing.TimeControl = timeControl;
                    _unitOfWork.MatchQueues.Update(existing);
                }
                else
                {
                    await _unitOfWork.MatchQueues.AddAsync(new Core.Entities.MatchQueue
                    {
                        Id = Guid.NewGuid(),
                        UserId = userId,
                        EloSnapshot = user.Elo,
                        Status = MatchQueueStatus.Waiting,
                        QueuedAt = DateTime.UtcNow,
                        TimeControl = timeControl,
                    });
                }
                await _unitOfWork.SaveChangesAsync();
                return new JoinQueueResultDto { Matched = false };
            }

            var opponent = await _unitOfWork.Users.GetByIdAsync(candidate.UserId)
                ?? throw new InvalidOperationException("Rakip kullanici bulunamadi.");

            // Randomize colors
            var userIsWhite = Random.Shared.Next(2) == 0;
            var (whiteUser, blackUser) = userIsWhite ? (user, opponent) : (opponent, user);

            var session = _sessionService.CreateSession(
                whiteUser.Id, whiteUser.Username, whiteUser.Elo,
                blackUser.Id, blackUser.Username, blackUser.Elo,
                candidate.TimeControl);

            _unitOfWork.MatchQueues.Remove(candidate);

            var mine = await _unitOfWork.MatchQueues.FirstOrDefaultAsync(q => q.UserId == userId);
            if (mine != null)
            {
                _unitOfWork.MatchQueues.Remove(mine);
            }

            await _unitOfWork.SaveChangesAsync();

            return BuildMatchedResult(session, userId);
        }
        finally
        {
            _queueLock.Release();
        }
    }

    public async Task<bool> LeaveQueueAsync(Guid userId)
    {
        await _queueLock.WaitAsync();
        try
        {
            var entry = await _unitOfWork.MatchQueues.FirstOrDefaultAsync(
                q => q.UserId == userId && q.Status == MatchQueueStatus.Waiting);
            if (entry == null) return false;

            _unitOfWork.MatchQueues.Remove(entry);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }
        finally
        {
            _queueLock.Release();
        }
    }

    public async Task<MatchmakingStatusDto> GetStatusAsync(Guid userId)
    {
        // Only surface a session as "active" if it is still in progress. Finished or
        // stale sessions are surfaced as no active game so the matchmaking screen
        // does not redirect the user back into a dead game while polling.
        var active = _sessionService.GetActiveSessionForUser(userId);
        if (active != null && !active.Finished)
        {
            return new MatchmakingStatusDto
            {
                InQueue = false,
                ActiveGameId = active.GameId,
            };
        }

        var entry = await _unitOfWork.MatchQueues.FirstOrDefaultAsync(
            q => q.UserId == userId && q.Status == MatchQueueStatus.Waiting);
        if (entry == null) return new MatchmakingStatusDto { InQueue = false };

        return new MatchmakingStatusDto
        {
            InQueue = true,
            QueuedAt = entry.QueuedAt,
            EloSnapshot = entry.EloSnapshot,
        };
    }

    public async Task<bool> AbandonActiveSessionAsync(Guid userId)
    {
        var active = _sessionService.GetActiveSessionForUser(userId);
        if (active == null) return false;

        if (!active.Finished)
        {
            var abandoningSide = active.SideOf(userId);
            var result = abandoningSide == "white" ? GameResult.BlackWin : GameResult.WhiteWin;
            _sessionService.FinishGame(active.GameId, result, "abandoned");
            try
            {
                await _gameService.PersistOnlineSessionAsync(active);
            }
            catch
            {
                // If persistence fails, still remove the session so the user can
                // start a new game. The orphan match record is acceptable.
            }
        }

        _sessionService.RemoveSession(active.GameId);
        return true;
    }

    private static JoinQueueResultDto BuildMatchedResult(
        OnlineGameSession session,
        Guid userId,
        bool resumed = false)
    {
        var (initialSeconds, incrementSeconds) = session.TimeControl.ToSpec();
        var userIsWhite = userId == session.WhiteUserId;

        return new JoinQueueResultDto
        {
            Matched = true,
            Resumed = resumed,
            GameId = session.GameId,
            OpponentId = session.OpponentOf(userId),
            OpponentUsername = userIsWhite ? session.BlackUsername : session.WhiteUsername,
            OpponentElo = userIsWhite ? session.BlackStartElo : session.WhiteStartElo,
            AssignedColor = session.SideOf(userId),
            StartFen = session.StartFen,
            TimeControl = (int)session.TimeControl,
            InitialSeconds = initialSeconds,
            IncrementSeconds = incrementSeconds,
        };
    }
}
