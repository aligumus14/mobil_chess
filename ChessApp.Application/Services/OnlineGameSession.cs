using ChessApp.Core.Enums;

namespace ChessApp.Application.Services;

public class OnlineGameSession
{
    public static readonly TimeSpan StartupGracePeriod = TimeSpan.FromMinutes(1);

    public Guid GameId { get; init; }
    public Guid WhiteUserId { get; init; }
    public Guid BlackUserId { get; init; }
    public string WhiteUsername { get; init; } = string.Empty;
    public string BlackUsername { get; init; } = string.Empty;
    public int WhiteStartElo { get; init; }
    public int BlackStartElo { get; init; }
    public string StartFen { get; init; } = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    public string CurrentFen { get; set; } = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    public string CurrentTurn { get; set; } = "white";
    public DateTime StartedAt { get; init; } = DateTime.UtcNow;
    public List<OnlineGameMove> Moves { get; } = new();
    public GameResult? Result { get; set; }
    public string? TerminationReason { get; set; }
    public Guid? PendingDrawOfferByUserId { get; set; }
    public bool Finished => Result.HasValue;
    public bool HasStarted => Moves.Count >= 2;
    public DateTime StartupDeadlineUtc => StartedAt.Add(StartupGracePeriod);

    // Connection tracking per side
    public string? WhiteConnectionId { get; set; }
    public string? BlackConnectionId { get; set; }

    // Time control / clocks. Times are stored in milliseconds. The clock for the
    // side whose turn it currently is starts ticking down from TurnStartedAt;
    // the other side's stored time is authoritative as-is. On a move:
    //   elapsed = now - TurnStartedAt
    //   activeRemaining -= elapsed
    //   activeRemaining += IncrementMs (if not the very first move-only state)
    //   TurnStartedAt = now (for the new active side)
    public OnlineTimeControl TimeControl { get; init; } = OnlineTimeControl.Blitz5;
    public int InitialMs { get; init; }
    public int IncrementMs { get; init; }
    public long WhiteRemainingMs { get; set; }
    public long BlackRemainingMs { get; set; }
    public DateTime TurnStartedAt { get; set; } = DateTime.UtcNow;

    public Guid OpponentOf(Guid userId) => userId == WhiteUserId ? BlackUserId : WhiteUserId;
    public string SideOf(Guid userId) => userId == WhiteUserId ? "white" : "black";
    public bool IsParticipant(Guid userId) => userId == WhiteUserId || userId == BlackUserId;

    public long ActiveRemainingMs(DateTime now)
    {
        var stored = CurrentTurn == "white" ? WhiteRemainingMs : BlackRemainingMs;
        if (!HasStarted) return stored;

        var elapsed = (long)Math.Max(0, (now - TurnStartedAt).TotalMilliseconds);
        return Math.Max(0, stored - elapsed);
    }
}

public class OnlineGameMove
{
    public int MoveNumber { get; init; }
    public Guid PlayerId { get; init; }
    public string FromSquare { get; init; } = string.Empty;
    public string ToSquare { get; init; } = string.Empty;
    public string San { get; init; } = string.Empty;
    public string FenAfterMove { get; init; } = string.Empty;
    public DateTime PlayedAt { get; init; } = DateTime.UtcNow;
}
