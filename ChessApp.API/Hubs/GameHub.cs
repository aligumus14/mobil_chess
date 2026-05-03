using System.Security.Claims;
using ChessApp.Application.Services;
using ChessApp.Core.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace ChessApp.API.Hubs;

[Authorize]
public class GameHub : Hub
{
    private readonly IGameSessionService _sessions;
    private readonly IGameService _gameService;

    public GameHub(IGameSessionService sessions, IGameService gameService)
    {
        _sessions = sessions;
        _gameService = gameService;
    }

    private Guid CurrentUserId()
    {
        var claim = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? throw new HubException("Yetkisiz.");
        return Guid.Parse(claim);
    }

    public async Task JoinGame(string gameId)
    {
        var userId = CurrentUserId();
        var gid = Guid.Parse(gameId);
        var session = _sessions.GetSession(gid)
            ?? throw new HubException("Oyun bulunamadi.");
        if (!session.IsParticipant(userId))
            throw new HubException("Bu oyunun katilimcisi degilsin.");

        _sessions.SetConnection(gid, userId, Context.ConnectionId);
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(gid));

        await Clients.Caller.SendAsync("GameState", new
        {
            gameId = session.GameId,
            whiteUserId = session.WhiteUserId,
            blackUserId = session.BlackUserId,
            whiteUsername = session.WhiteUsername,
            blackUsername = session.BlackUsername,
            whiteElo = session.WhiteStartElo,
            blackElo = session.BlackStartElo,
            currentFen = session.CurrentFen,
            currentTurn = session.CurrentTurn,
            yourColor = session.SideOf(userId),
            moves = session.Moves,
            finished = session.Finished,
            opponentOnline = session.SideOf(userId) == "white"
                ? !string.IsNullOrWhiteSpace(session.BlackConnectionId)
                : !string.IsNullOrWhiteSpace(session.WhiteConnectionId),
        });

        await Clients.Caller.SendAsync("MatchFound", new
        {
            gameId = session.GameId,
            opponentId = session.OpponentOf(userId),
            opponentUsername = session.SideOf(userId) == "white" ? session.BlackUsername : session.WhiteUsername,
            opponentElo = session.SideOf(userId) == "white" ? session.BlackStartElo : session.WhiteStartElo,
            assignedColor = session.SideOf(userId),
            startFen = session.StartFen,
        });

        await Clients.OthersInGroup(GroupName(gid)).SendAsync("OpponentConnected");
    }

    public async Task MakeMove(string gameId, string fromSquare, string toSquare, string san, string fenAfterMove)
    {
        var userId = CurrentUserId();
        var gid = Guid.Parse(gameId);
        var move = _sessions.AppendMove(gid, userId, fromSquare, toSquare, san, fenAfterMove);

        await Clients.Group(GroupName(gid)).SendAsync("MovePlayed", new
        {
            gameId = gid,
            move.MoveNumber,
            playerId = userId,
            move.FromSquare,
            move.ToSquare,
            move.San,
            move.FenAfterMove,
            playedAt = move.PlayedAt,
        });

        await Clients.OthersInGroup(GroupName(gid)).SendAsync("OpponentMove", new
        {
            gameId = gid,
            move.MoveNumber,
            playerId = userId,
            move.FromSquare,
            move.ToSquare,
            move.San,
            move.FenAfterMove,
            playedAt = move.PlayedAt,
        });
    }

    public async Task OfferDraw(string gameId)
    {
        var userId = CurrentUserId();
        var gid = Guid.Parse(gameId);
        var offered = _sessions.OfferDraw(gid, userId);
        if (!offered)
        {
            return;
        }

        await Clients.OthersInGroup(GroupName(gid)).SendAsync("DrawOffered", new
        {
            gameId = gid,
            fromUserId = userId,
        });
    }

    public async Task AcceptDraw(string gameId)
    {
        var gid = Guid.Parse(gameId);
        var userId = CurrentUserId();
        var session = _sessions.AcceptDraw(gid, userId);

        var (whiteDelta, blackDelta) = await _gameService.PersistOnlineSessionAsync(session);

        await Clients.Group(GroupName(gid)).SendAsync("GameEnded", new
        {
            gameId = gid,
            result = GameResult.Draw.ToString(),
            reason = "draw-agreed",
            whiteDelta,
            blackDelta,
        });

        _sessions.RemoveSession(gid);
    }

    public async Task ReportGameEnd(string gameId, string result, string reason)
    {
        var userId = CurrentUserId();
        var gid = Guid.Parse(gameId);
        var session = _sessions.GetSession(gid)
            ?? throw new HubException("Oyun bulunamadi.");
        if (!session.IsParticipant(userId))
            throw new HubException("Bu oyunun katilimcisi degilsin.");
        if (session.Finished) return;

        var parsedResult = ParseResult(result);
        _sessions.FinishGame(gid, parsedResult, reason);

        var (whiteDelta, blackDelta) = await _gameService.PersistOnlineSessionAsync(session);

        await Clients.Group(GroupName(gid)).SendAsync("GameEnded", new
        {
            gameId = gid,
            result = parsedResult.ToString(),
            reason,
            whiteDelta,
            blackDelta,
        });

        _sessions.RemoveSession(gid);
    }

    public async Task Resign(string gameId)
    {
        var userId = CurrentUserId();
        var gid = Guid.Parse(gameId);
        var session = _sessions.GetSession(gid)
            ?? throw new HubException("Oyun bulunamadi.");
        if (!session.IsParticipant(userId))
            throw new HubException("Bu oyunun katilimcisi degilsin.");
        if (session.Finished) return;

        var resigningSide = session.SideOf(userId);
        var result = resigningSide == "white" ? GameResult.BlackWin : GameResult.WhiteWin;
        _sessions.FinishGame(gid, result, "resign");

        var (whiteDelta, blackDelta) = await _gameService.PersistOnlineSessionAsync(session);

        await Clients.Group(GroupName(gid)).SendAsync("GameEnded", new
        {
            gameId = gid,
            result = result.ToString(),
            reason = "resign",
            whiteDelta,
            blackDelta,
        });

        _sessions.RemoveSession(gid);
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userIdClaim = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (Guid.TryParse(userIdClaim, out var userId))
        {
            var session = _sessions.GetActiveSessionForUser(userId);
            if (session != null)
            {
                _sessions.SetConnection(session.GameId, userId, null);
                await Clients.Group(GroupName(session.GameId)).SendAsync("OpponentDisconnected");
            }
        }
        await base.OnDisconnectedAsync(exception);
    }

    private static string GroupName(Guid gameId) => $"game-{gameId}";

    private static GameResult ParseResult(string s) => s?.ToLowerInvariant() switch
    {
        "whitewin" or "white" or "1-0" => GameResult.WhiteWin,
        "blackwin" or "black" or "0-1" => GameResult.BlackWin,
        "draw" or "1/2-1/2" => GameResult.Draw,
        _ => throw new HubException("Gecersiz sonuc."),
    };
}
