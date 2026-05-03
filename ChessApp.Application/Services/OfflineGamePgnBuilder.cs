using System.Text;
using ChessApp.Application.DTOs;
using ChessApp.Core.Enums;

namespace ChessApp.Application.Services;

internal static class OfflineGamePgnBuilder
{
    private const string InitialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    public static string Build(CreateGameDto dto)
    {
        var endedAt = NormalizeEndedAt(dto.EndedAt);
        var playerColor = NormalizePlayerColor(dto.PlayerColor);
        var difficulty = NormalizeDifficulty(dto.BotDifficulty);
        var result = ToResultTag(dto.Result);
        var startFen = string.IsNullOrWhiteSpace(dto.StartFen) ? InitialFen : dto.StartFen.Trim();
        var botLabel = string.IsNullOrWhiteSpace(difficulty) ? "Bot" : $"Bot ({difficulty})";

        var headers = new List<string>
        {
            Header("Event", "Offline Bot Match"),
            Header("Site", "ChessApp"),
            Header("Date", endedAt.ToString("yyyy.MM.dd")),
            Header("UTCDate", endedAt.ToString("yyyy.MM.dd")),
            Header("UTCTime", endedAt.ToString("HH:mm:ss")),
            Header("Round", "-"),
            Header("White", playerColor == "white" ? "Player" : botLabel),
            Header("Black", playerColor == "black" ? "Player" : botLabel),
            Header("Result", result),
            Header("PlayerColor", playerColor),
        };

        if (!string.IsNullOrWhiteSpace(difficulty))
        {
            headers.Add(Header("BotDifficulty", difficulty));
        }

        if (!string.IsNullOrWhiteSpace(dto.TimeControl))
        {
            headers.Add(Header("TimeControl", dto.TimeControl.Trim()));
        }

        if (!string.IsNullOrWhiteSpace(dto.TerminationReason))
        {
            headers.Add(Header("Termination", dto.TerminationReason.Trim()));
        }

        if (!startFen.Equals(InitialFen, StringComparison.Ordinal))
        {
            headers.Add(Header("SetUp", "1"));
            headers.Add(Header("FEN", startFen));
        }

        var moves = dto.Moves
            .OrderBy(m => m.MoveNumber)
            .Select(m => m.San?.Trim())
            .Where(san => !string.IsNullOrWhiteSpace(san))
            .Cast<string>()
            .ToList();

        var moveText = moves.Count > 0
            ? BuildMoveText(moves, result)
            : BuildFallbackMoveText(dto.Pgn, result);

        return string.Join("\n", headers) + "\n\n" + moveText;
    }

    private static string BuildMoveText(IReadOnlyList<string> moves, string result)
    {
        var builder = new StringBuilder();

        for (var index = 0; index < moves.Count; index++)
        {
            if (index > 0)
            {
                builder.Append(' ');
            }

            if (index % 2 == 0)
            {
                builder.Append(index / 2 + 1);
                builder.Append(". ");
            }

            builder.Append(moves[index]);
        }

        if (builder.Length > 0)
        {
            builder.Append(' ');
        }

        builder.Append(result);
        return builder.ToString().Trim();
    }

    private static string BuildFallbackMoveText(string? providedPgn, string result)
    {
        if (string.IsNullOrWhiteSpace(providedPgn))
        {
            return result;
        }

        var lines = providedPgn
            .Replace("\r", string.Empty, StringComparison.Ordinal)
            .Split('\n');

        var moveLines = new List<string>();
        var inMoveSection = false;

        foreach (var rawLine in lines)
        {
            var line = rawLine.Trim();
            if (line.Length == 0)
            {
                inMoveSection = true;
                continue;
            }

            if (!inMoveSection && line.StartsWith("[", StringComparison.Ordinal))
            {
                continue;
            }

            inMoveSection = true;
            moveLines.Add(line);
        }

        var moveText = string.Join(" ", moveLines).Trim();
        if (moveText.Length == 0)
        {
            return result;
        }

        return EnsureTrailingResult(moveText, result);
    }

    private static string EnsureTrailingResult(string moveText, string result)
    {
        var resultTags = new[] { "1-0", "0-1", "1/2-1/2", "*" };

        foreach (var tag in resultTags)
        {
            if (moveText.EndsWith(" " + tag, StringComparison.Ordinal) ||
                moveText.Equals(tag, StringComparison.Ordinal))
            {
                moveText = moveText[..^tag.Length].TrimEnd();
                break;
            }
        }

        return string.Concat(moveText, " ", result).Trim();
    }

    private static string NormalizePlayerColor(string? playerColor)
    {
        return string.Equals(playerColor, "black", StringComparison.OrdinalIgnoreCase)
            ? "black"
            : "white";
    }

    private static string? NormalizeDifficulty(string? difficulty)
    {
        if (string.IsNullOrWhiteSpace(difficulty))
        {
            return null;
        }

        return difficulty.Trim().ToLowerInvariant();
    }

    private static DateTime NormalizeEndedAt(DateTime endedAt)
    {
        if (endedAt == default)
        {
            return DateTime.UtcNow;
        }

        return endedAt.ToUniversalTime();
    }

    private static string ToResultTag(GameResult result)
    {
        return result switch
        {
            GameResult.WhiteWin => "1-0",
            GameResult.BlackWin => "0-1",
            _ => "1/2-1/2",
        };
    }

    private static string Header(string name, string value)
    {
        var escaped = value
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("\"", "\\\"", StringComparison.Ordinal);

        return $"[{name} \"{escaped}\"]";
    }
}
