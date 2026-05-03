using ChessApp.Application.DTOs;
using ChessApp.Core.Entities;
using ChessApp.Core.Enums;
using ChessApp.Core.Interfaces;

namespace ChessApp.Application.Services;

public class GameService : IGameService
{
    private readonly IUnitOfWork _unitOfWork;
    private const string InitialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    public GameService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<Guid> CreateOfflineGameAsync(Guid userId, CreateGameDto dto)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId)
            ?? throw new KeyNotFoundException("Kullanici bulunamadi.");
        var playerIsWhite = dto.PlayerColor.Equals("white", StringComparison.OrdinalIgnoreCase);
        var startedAt = NormalizeStartedAt(dto.StartedAt);
        var endedAt = NormalizeEndedAt(dto.EndedAt, startedAt);
        var startFen = string.IsNullOrWhiteSpace(dto.StartFen) ? InitialFen : dto.StartFen.Trim();
        var finalFen = string.IsNullOrWhiteSpace(dto.FinalFen) ? startFen : dto.FinalFen.Trim();
        var pgn = OfflineGamePgnBuilder.Build(dto);

        var game = new Game
        {
            Id = Guid.NewGuid(),
            WhitePlayerId = userId,
            BlackPlayerId = userId,
            GameType = dto.GameType,
            Status = GameStatus.Finished,
            Result = dto.Result,
            StartFen = startFen,
            CurrentFen = finalFen,
            Pgn = pgn,
            WinnerUserId = ResolveWinnerId(dto.Result, userId, playerIsWhite),
            StartedAt = startedAt,
            EndedAt = endedAt,
        };

        await _unitOfWork.Games.AddAsync(game);

        foreach (var m in dto.Moves.OrderBy(move => move.MoveNumber))
        {
            await _unitOfWork.GameMoves.AddAsync(new GameMove
            {
                Id = Guid.NewGuid(),
                GameId = game.Id,
                MoveNumber = m.MoveNumber,
                PlayerId = userId,
                FromSquare = m.FromSquare,
                ToSquare = m.ToSquare,
                San = m.San,
                FenAfterMove = m.FenAfterMove,
                PlayedAt = DateTime.UtcNow,
            });
        }

        ApplyResultToStats(user, dto.Result, playerIsWhite);
        _unitOfWork.Users.Update(user);

        await _unitOfWork.SaveChangesAsync();
        return game.Id;
    }

    public async Task<PagedResultDto<GameListItemDto>> GetUserGamesAsync(Guid userId, int page, int pageSize)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var all = (await _unitOfWork.Games.FindAsync(
            g => g.WhitePlayerId == userId || g.BlackPlayerId == userId))
            .OrderByDescending(g => g.StartedAt)
            .ToList();

        var total = all.Count;
        var pageItems = all.Skip((page - 1) * pageSize).Take(pageSize).ToList();

        var gameIds = pageItems.Select(g => g.Id).ToList();
        var movesByGame = (await _unitOfWork.GameMoves.FindAsync(m => gameIds.Contains(m.GameId)))
            .GroupBy(m => m.GameId)
            .ToDictionary(g => g.Key, g => g.Count());

        var items = pageItems.Select(g => new GameListItemDto
        {
            Id = g.Id,
            GameType = g.GameType,
            Result = g.Result,
            PlayerColor = ResolvePlayerColor(g, userId),
            PlayerWon = g.WinnerUserId == userId,
            BotDifficulty = ExtractBotDifficulty(g.Pgn),
            MoveCount = movesByGame.TryGetValue(g.Id, out var c) ? c : 0,
            StartedAt = g.StartedAt,
            EndedAt = g.EndedAt,
        }).ToList();

        return new PagedResultDto<GameListItemDto>
        {
            Items = items,
            Page = page,
            PageSize = pageSize,
            TotalCount = total,
        };
    }

    public async Task<(int WhiteDelta, int BlackDelta)> PersistOnlineSessionAsync(OnlineGameSession session)
    {
        if (session.Result is null)
            throw new InvalidOperationException("Sonuclanmamis oyun kaydedilemez.");

        var whiteUser = await _unitOfWork.Users.GetByIdAsync(session.WhiteUserId)
            ?? throw new InvalidOperationException("Beyaz oyuncu bulunamadi.");
        var blackUser = await _unitOfWork.Users.GetByIdAsync(session.BlackUserId)
            ?? throw new InvalidOperationException("Siyah oyuncu bulunamadi.");

        var result = session.Result.Value;
        var (whiteDelta, blackDelta) = EloCalculator.Compute(whiteUser.Elo, blackUser.Elo, result);

        var endedAt = DateTime.UtcNow;
        var game = new Game
        {
            Id = session.GameId,
            WhitePlayerId = whiteUser.Id,
            BlackPlayerId = blackUser.Id,
            GameType = GameType.Online,
            Status = GameStatus.Finished,
            Result = result,
            StartFen = session.StartFen,
            CurrentFen = session.CurrentFen,
            Pgn = BuildOnlinePgn(session, whiteUser.Username, blackUser.Username, result),
            WinnerUserId = result switch
            {
                GameResult.WhiteWin => whiteUser.Id,
                GameResult.BlackWin => blackUser.Id,
                _ => (Guid?)null,
            },
            StartedAt = session.StartedAt,
            EndedAt = endedAt,
        };
        await _unitOfWork.Games.AddAsync(game);

        foreach (var m in session.Moves.OrderBy(x => x.MoveNumber))
        {
            await _unitOfWork.GameMoves.AddAsync(new GameMove
            {
                Id = Guid.NewGuid(),
                GameId = game.Id,
                MoveNumber = m.MoveNumber,
                PlayerId = m.PlayerId,
                FromSquare = m.FromSquare,
                ToSquare = m.ToSquare,
                San = m.San,
                FenAfterMove = m.FenAfterMove,
                PlayedAt = m.PlayedAt,
            });
        }

        var whiteOld = whiteUser.Elo;
        var blackOld = blackUser.Elo;
        whiteUser.Elo = whiteOld + whiteDelta;
        blackUser.Elo = blackOld + blackDelta;
        ApplyOnlineResultToStats(whiteUser, blackUser, result);
        _unitOfWork.Users.Update(whiteUser);
        _unitOfWork.Users.Update(blackUser);

        await _unitOfWork.EloHistories.AddAsync(new EloHistory
        {
            Id = Guid.NewGuid(),
            UserId = whiteUser.Id,
            GameId = game.Id,
            OldElo = whiteOld,
            NewElo = whiteUser.Elo,
            ChangeAmount = whiteDelta,
            CreatedAt = endedAt,
        });
        await _unitOfWork.EloHistories.AddAsync(new EloHistory
        {
            Id = Guid.NewGuid(),
            UserId = blackUser.Id,
            GameId = game.Id,
            OldElo = blackOld,
            NewElo = blackUser.Elo,
            ChangeAmount = blackDelta,
            CreatedAt = endedAt,
        });

        await _unitOfWork.SaveChangesAsync();
        return (whiteDelta, blackDelta);
    }

    private static void ApplyOnlineResultToStats(User white, User black, GameResult result)
    {
        switch (result)
        {
            case GameResult.WhiteWin:
                white.Wins++;
                black.Losses++;
                break;
            case GameResult.BlackWin:
                black.Wins++;
                white.Losses++;
                break;
            default:
                white.Draws++;
                black.Draws++;
                break;
        }
    }

    private static string BuildOnlinePgn(OnlineGameSession session, string whiteName, string blackName, GameResult result)
    {
        var resultTag = result switch
        {
            GameResult.WhiteWin => "1-0",
            GameResult.BlackWin => "0-1",
            _ => "1/2-1/2",
        };
        var date = session.StartedAt.ToString("yyyy.MM.dd");
        var sb = new System.Text.StringBuilder();
        sb.AppendLine($"[Event \"Online Match\"]");
        sb.AppendLine($"[Site \"ChessApp\"]");
        sb.AppendLine($"[Date \"{date}\"]");
        sb.AppendLine($"[White \"{whiteName}\"]");
        sb.AppendLine($"[Black \"{blackName}\"]");
        sb.AppendLine($"[Result \"{resultTag}\"]");
        sb.AppendLine($"[PlayerColor \"white\"]");
        if (!string.IsNullOrWhiteSpace(session.TerminationReason))
            sb.AppendLine($"[Termination \"{session.TerminationReason}\"]");
        sb.AppendLine();

        var moves = session.Moves.OrderBy(m => m.MoveNumber).ToList();
        for (int i = 0; i < moves.Count; i++)
        {
            if (i % 2 == 0) sb.Append($"{(i / 2) + 1}. ");
            sb.Append(moves[i].San);
            sb.Append(' ');
        }
        sb.Append(resultTag);
        return sb.ToString();
    }

    public async Task<GameDetailDto?> GetGameDetailAsync(Guid gameId, Guid userId)
    {
        var game = await _unitOfWork.Games.GetByIdAsync(gameId);
        if (game == null) return null;
        if (game.WhitePlayerId != userId && game.BlackPlayerId != userId) return null;

        var moves = (await _unitOfWork.GameMoves.FindAsync(m => m.GameId == gameId))
            .OrderBy(m => m.MoveNumber)
            .ToList();

        return new GameDetailDto
        {
            Id = game.Id,
            GameType = game.GameType,
            Result = game.Result,
            PlayerColor = ResolvePlayerColor(game, userId),
            PlayerWon = game.WinnerUserId == userId,
            BotDifficulty = ExtractBotDifficulty(game.Pgn),
            StartFen = game.StartFen,
            CurrentFen = game.CurrentFen,
            Pgn = game.Pgn,
            StartedAt = game.StartedAt,
            EndedAt = game.EndedAt,
            Moves = moves.Select(m => new GameMoveDto
            {
                MoveNumber = m.MoveNumber,
                FromSquare = m.FromSquare,
                ToSquare = m.ToSquare,
                San = m.San,
                FenAfterMove = m.FenAfterMove,
                PlayedAt = m.PlayedAt,
            }).ToList(),
        };
    }

    private static Guid? ResolveWinnerId(GameResult result, Guid userId, bool playerIsWhite)
    {
        return result switch
        {
            GameResult.WhiteWin => playerIsWhite ? userId : (Guid?)null,
            GameResult.BlackWin => !playerIsWhite ? userId : (Guid?)null,
            _ => null,
        };
    }

    private static void ApplyResultToStats(User user, GameResult result, bool playerIsWhite)
    {
        switch (result)
        {
            case GameResult.Draw:
                user.Draws++;
                return;
            case GameResult.WhiteWin when playerIsWhite:
            case GameResult.BlackWin when !playerIsWhite:
                user.Wins++;
                return;
            default:
                user.Losses++;
                return;
        }
    }

    private static DateTime NormalizeStartedAt(DateTime startedAt)
    {
        if (startedAt == default)
        {
            return DateTime.UtcNow;
        }

        return startedAt.ToUniversalTime();
    }

    private static DateTime NormalizeEndedAt(DateTime endedAt, DateTime startedAt)
    {
        if (endedAt == default)
        {
            return startedAt;
        }

        var normalized = endedAt.ToUniversalTime();
        return normalized < startedAt ? startedAt : normalized;
    }

    private static string? ExtractBotDifficulty(string? pgn)
    {
        return ExtractPgnHeaderValue(pgn, "BotDifficulty");
    }

    private static string ExtractPlayerColor(string? pgn)
    {
        return ExtractPgnHeaderValue(pgn, "PlayerColor") ?? "white";
    }

    private static string ResolvePlayerColor(Game game, Guid userId)
    {
        if (game.GameType == GameType.Online)
        {
            return game.WhitePlayerId == userId ? "white" : "black";
        }

        return ExtractPlayerColor(game.Pgn);
    }

    private static string? ExtractPgnHeaderValue(string? pgn, string headerName)
    {
        if (string.IsNullOrWhiteSpace(pgn))
        {
            return null;
        }

        var marker = $"[{headerName} \"";
        var idx = pgn.IndexOf(marker, StringComparison.Ordinal);
        if (idx < 0)
        {
            return null;
        }

        var start = idx + marker.Length;
        var end = pgn.IndexOf('"', start);
        if (end < 0)
        {
            return null;
        }

        return pgn.Substring(start, end - start);
    }
}
