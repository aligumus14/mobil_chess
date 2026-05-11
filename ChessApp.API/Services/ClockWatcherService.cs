using ChessApp.API.Hubs;
using ChessApp.Application.Services;
using ChessApp.Core.Enums;
using Microsoft.AspNetCore.SignalR;

namespace ChessApp.API.Services;

/// Periodically scans active in-memory sessions and finalizes any whose active
/// side has run out of time (flag fall). Server is the authority on time.
public class ClockWatcherService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<ClockWatcherService> _logger;
    private static readonly TimeSpan TickInterval = TimeSpan.FromMilliseconds(500);

    public ClockWatcherService(IServiceProvider services, ILogger<ClockWatcherService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await TickAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ClockWatcher tick failed");
            }
            try
            {
                await Task.Delay(TickInterval, stoppingToken);
            }
            catch (TaskCanceledException) { return; }
        }
    }

    private async Task TickAsync()
    {
        using var scope = _services.CreateScope();
        var sessions = scope.ServiceProvider.GetRequiredService<IGameSessionService>();
        var gameService = scope.ServiceProvider.GetRequiredService<IGameService>();
        var hub = scope.ServiceProvider.GetRequiredService<IHubContext<GameHub>>();

        var now = DateTime.UtcNow;
        foreach (var session in sessions.GetActiveSessions().ToList())
        {
            if (session.Finished) continue;
            if (!session.HasStarted)
            {
                if (now < session.StartupDeadlineUtc) continue;

                sessions.FinishGame(session.GameId, GameResult.Draw, "start-timeout");
                await hub.Clients.Group($"game-{session.GameId}").SendAsync("GameEnded", new
                {
                    gameId = session.GameId,
                    result = "Cancelled",
                    reason = "start-timeout",
                    whiteDelta = 0,
                    blackDelta = 0,
                });
                sessions.RemoveSession(session.GameId);
                continue;
            }

            var elapsed = (long)Math.Max(0, (now - session.TurnStartedAt).TotalMilliseconds);
            var stored = session.CurrentTurn == "white"
                ? session.WhiteRemainingMs
                : session.BlackRemainingMs;
            if (stored - elapsed > 0) continue;

            // Active side flagged.
            var winner = session.CurrentTurn == "white" ? GameResult.BlackWin : GameResult.WhiteWin;
            if (session.CurrentTurn == "white")
                session.WhiteRemainingMs = 0;
            else
                session.BlackRemainingMs = 0;

            sessions.FinishGame(session.GameId, winner, "time-out");

            (int whiteDelta, int blackDelta) deltas = (0, 0);
            try
            {
                deltas = await gameService.PersistOnlineSessionAsync(session);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Persist on flag-fall failed for {GameId}", session.GameId);
            }

            await hub.Clients.Group($"game-{session.GameId}").SendAsync("GameEnded", new
            {
                gameId = session.GameId,
                result = winner.ToString(),
                reason = "time-out",
                whiteDelta = deltas.whiteDelta,
                blackDelta = deltas.blackDelta,
            });

            sessions.RemoveSession(session.GameId);
        }
    }
}
