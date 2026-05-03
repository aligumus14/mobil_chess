using ChessApp.Core.Enums;

namespace ChessApp.Application.Services;

public class OnlineGameSession
{
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

    // Connection tracking per side
    public string? WhiteConnectionId { get; set; }
    public string? BlackConnectionId { get; set; }

    public Guid OpponentOf(Guid userId) => userId == WhiteUserId ? BlackUserId : WhiteUserId;
    public string SideOf(Guid userId) => userId == WhiteUserId ? "white" : "black";
    public bool IsParticipant(Guid userId) => userId == WhiteUserId || userId == BlackUserId;
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
