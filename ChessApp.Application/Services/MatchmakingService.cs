using ChessApp.Application.DTOs;
using ChessApp.Core.Enums;
using ChessApp.Core.Interfaces;

namespace ChessApp.Application.Services;

public class MatchmakingService : IMatchmakingService
{
    private const int EloRange = 100;
    private static readonly SemaphoreSlim _queueLock = new(1, 1);

    private readonly IUnitOfWork _unitOfWork;
    private readonly IGameSessionService _sessionService;

    public MatchmakingService(IUnitOfWork unitOfWork, IGameSessionService sessionService)
    {
        _unitOfWork = unitOfWork;
        _sessionService = sessionService;
    }

    public async Task<JoinQueueResultDto> JoinQueueAsync(Guid userId)
    {
        await _queueLock.WaitAsync();
        try
        {
            var active = _sessionService.GetActiveSessionForUser(userId);
            if (active != null)
            {
                return new JoinQueueResultDto
                {
                    Matched = true,
                    GameId = active.GameId,
                    OpponentId = active.OpponentOf(userId),
                    OpponentUsername = userId == active.WhiteUserId ? active.BlackUsername : active.WhiteUsername,
                    OpponentElo = userId == active.WhiteUserId ? active.BlackStartElo : active.WhiteStartElo,
                    AssignedColor = active.SideOf(userId),
                    StartFen = active.StartFen,
                };
            }

            var user = await _unitOfWork.Users.GetByIdAsync(userId)
                ?? throw new InvalidOperationException("Kullanici bulunamadi.");

            var waiting = (await _unitOfWork.MatchQueues.FindAsync(
                q => q.Status == MatchQueueStatus.Waiting && q.UserId != userId))
                .OrderBy(q => Math.Abs(q.EloSnapshot - user.Elo))
                .ThenBy(q => q.QueuedAt)
                .ToList();

            var candidate = waiting.FirstOrDefault(q => Math.Abs(q.EloSnapshot - user.Elo) <= EloRange);

            if (candidate == null)
            {
                var existing = await _unitOfWork.MatchQueues.FirstOrDefaultAsync(q => q.UserId == userId);
                if (existing != null)
                {
                    existing.Status = MatchQueueStatus.Waiting;
                    existing.EloSnapshot = user.Elo;
                    existing.QueuedAt = DateTime.UtcNow;
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
                blackUser.Id, blackUser.Username, blackUser.Elo);

            candidate.Status = MatchQueueStatus.Matched;
            _unitOfWork.MatchQueues.Update(candidate);

            var mine = await _unitOfWork.MatchQueues.FirstOrDefaultAsync(q => q.UserId == userId);
            if (mine != null)
            {
                mine.Status = MatchQueueStatus.Matched;
                _unitOfWork.MatchQueues.Update(mine);
            }

            await _unitOfWork.SaveChangesAsync();

            return new JoinQueueResultDto
            {
                Matched = true,
                GameId = session.GameId,
                OpponentId = opponent.Id,
                OpponentUsername = opponent.Username,
                OpponentElo = opponent.Elo,
                AssignedColor = userIsWhite ? "white" : "black",
                StartFen = session.StartFen,
            };
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
        var active = _sessionService.GetActiveSessionForUser(userId);
        if (active != null)
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
}
