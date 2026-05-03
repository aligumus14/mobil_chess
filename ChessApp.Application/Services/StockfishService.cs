using System.Diagnostics;
using Microsoft.Extensions.Configuration;

namespace ChessApp.Application.Services;

public sealed class StockfishService : IStockfishService
{
    private readonly string _executablePath;
    private readonly int _defaultDepth;
    private readonly TimeSpan _readTimeout;
    private Process? _process;
    private StreamWriter? _input;
    private StreamReader? _output;
    private bool _initialized;

    public StockfishService(IConfiguration configuration)
    {
        _executablePath = configuration["Stockfish:ExecutablePath"]?.Trim() ?? "stockfish";
        if (string.IsNullOrWhiteSpace(_executablePath))
        {
            _executablePath = "stockfish";
        }
        _defaultDepth = ParsePositiveInt(configuration["Stockfish:AnalysisDepth"], fallback: 10);
        var timeoutMs = ParsePositiveInt(configuration["Stockfish:ReadTimeoutMs"], fallback: 15000);
        _readTimeout = TimeSpan.FromMilliseconds(timeoutMs);
    }

    public async Task<StockfishAnalysisResult> AnalyzePositionAsync(
        string fen,
        int? depth = null,
        CancellationToken cancellationToken = default)
    {
        return await GetBestMoveAsync(
            fen,
            moveTimeMs: null,
            depth: depth,
            cancellationToken: cancellationToken);
    }

    public async Task<StockfishAnalysisResult> GetBestMoveAsync(
        string fen,
        int? moveTimeMs = null,
        int? depth = null,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(fen))
        {
            throw new InvalidOperationException("Analiz edilecek FEN bos olamaz.");
        }

        await EnsureStartedAsync(cancellationToken);
        await SendCommandAsync("ucinewgame");
        await SendCommandAsync("isready");
        await WaitForTokenAsync("readyok", cancellationToken);
        await SendCommandAsync($"position fen {fen.Trim()}");
        if (moveTimeMs is > 0)
        {
            await SendCommandAsync($"go movetime {moveTimeMs.Value}");
        }
        else
        {
            await SendCommandAsync($"go depth {depth ?? _defaultDepth}");
        }

        double evaluationCp = 0;
        var bestMove = string.Empty;

        while (true)
        {
            var line = await ReadLineAsync(cancellationToken);
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            if (line.StartsWith("info ", StringComparison.Ordinal))
            {
                evaluationCp = ExtractEvaluation(line, evaluationCp);
                continue;
            }

            if (line.StartsWith("bestmove ", StringComparison.Ordinal))
            {
                bestMove = ParseBestMove(line);
                break;
            }
        }

        return new StockfishAnalysisResult
        {
            BestMove = bestMove,
            EvaluationCp = evaluationCp,
        };
    }

    public void Dispose()
    {
        try
        {
            if (_process is { HasExited: false })
            {
                _process.Kill(entireProcessTree: true);
            }
        }
        catch
        {
            // Best effort cleanup.
        }
        finally
        {
            _process?.Dispose();
            _process = null;
            _input = null;
            _output = null;
            _initialized = false;
        }
    }

    private async Task EnsureStartedAsync(CancellationToken cancellationToken)
    {
        if (_initialized)
        {
            return;
        }

        if (Path.IsPathRooted(_executablePath) && !File.Exists(_executablePath))
        {
            throw new InvalidOperationException($"Stockfish bulunamadi: {_executablePath}");
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = _executablePath,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };

        _process = Process.Start(startInfo)
            ?? throw new InvalidOperationException("Stockfish process baslatilamadi.");
        _input = _process.StandardInput;
        _output = _process.StandardOutput;

        await SendCommandAsync("uci");
        await WaitForTokenAsync("uciok", cancellationToken);
        await SendCommandAsync("isready");
        await WaitForTokenAsync("readyok", cancellationToken);
        _initialized = true;
    }

    private async Task SendCommandAsync(string command)
    {
        if (_input == null)
        {
            throw new InvalidOperationException("Stockfish giris akisi hazir degil.");
        }

        await _input.WriteLineAsync(command);
        await _input.FlushAsync();
    }

    private async Task WaitForTokenAsync(string expectedToken, CancellationToken cancellationToken)
    {
        while (true)
        {
            var line = await ReadLineAsync(cancellationToken);
            if (line.Contains(expectedToken, StringComparison.Ordinal))
            {
                return;
            }
        }
    }

    private async Task<string> ReadLineAsync(CancellationToken cancellationToken)
    {
        if (_output == null)
        {
            throw new InvalidOperationException("Stockfish cikis akisi hazir degil.");
        }

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(_readTimeout);

        var readTask = _output.ReadLineAsync();
        var completedTask = await Task.WhenAny(readTask, Task.Delay(Timeout.InfiniteTimeSpan, timeoutCts.Token));
        if (completedTask != readTask)
        {
            throw new InvalidOperationException("Stockfish yanit vermedi. Timeout olustu.");
        }

        var line = await readTask;
        if (line == null)
        {
            throw new InvalidOperationException("Stockfish beklenmedik sekilde kapandi.");
        }

        return line;
    }

    private static string ParseBestMove(string line)
    {
        var parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length >= 2 ? parts[1] : string.Empty;
    }

    private static double ExtractEvaluation(string line, double fallbackValue)
    {
        var parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        for (var index = 0; index < parts.Length - 2; index++)
        {
            if (!parts[index].Equals("score", StringComparison.Ordinal))
            {
                continue;
            }

            var scoreType = parts[index + 1];
            var rawValue = parts[index + 2];
            if (!int.TryParse(rawValue, out var parsed))
            {
                return fallbackValue;
            }

            return scoreType switch
            {
                "cp" => parsed,
                "mate" => parsed > 0 ? 100000 - parsed : -100000 - parsed,
                _ => fallbackValue,
            };
        }

        return fallbackValue;
    }

    private static int ParsePositiveInt(string? rawValue, int fallback)
    {
        return int.TryParse(rawValue, out var parsed) && parsed > 0
            ? parsed
            : fallback;
    }
}
