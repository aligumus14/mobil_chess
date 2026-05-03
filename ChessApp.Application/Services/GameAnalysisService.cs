using ChessApp.Application.DTOs;
using ChessApp.Core.Entities;
using ChessApp.Core.Enums;
using ChessApp.Core.Interfaces;

namespace ChessApp.Application.Services;

public class GameAnalysisService : IGameAnalysisService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IStockfishService _stockfish;

    public GameAnalysisService(IUnitOfWork unitOfWork, IStockfishService stockfish)
    {
        _unitOfWork = unitOfWork;
        _stockfish = stockfish;
    }

    public async Task<GameAnalysisDto?> GetGameAnalysisAsync(Guid gameId, Guid userId)
    {
        var game = await RequireAccessibleGameAsync(gameId, userId);
        var moves = (await _unitOfWork.GameMoves.FindAsync(m => m.GameId == gameId))
            .OrderBy(m => m.MoveNumber)
            .ToList();
        var analysisRows = (await _unitOfWork.AnalysisResults.FindAsync(a => a.GameId == gameId))
            .OrderBy(a => a.MoveNumber)
            .ToList();

        if (analysisRows.Count == 0)
        {
            return null;
        }

        return BuildDto(game, moves, analysisRows);
    }

    public async Task<GameAnalysisDto> AnalyzeGameAsync(Guid gameId, Guid userId, bool force = false)
    {
        var game = await RequireAccessibleGameAsync(gameId, userId);
        if (game.Status != GameStatus.Finished)
        {
            throw new InvalidOperationException("Yalnizca bitmis oyunlar analiz edilebilir.");
        }

        var moves = (await _unitOfWork.GameMoves.FindAsync(m => m.GameId == gameId))
            .OrderBy(m => m.MoveNumber)
            .ToList();
        var existingRows = (await _unitOfWork.AnalysisResults.FindAsync(a => a.GameId == gameId))
            .OrderBy(a => a.MoveNumber)
            .ToList();

        foreach (var row in existingRows)
        {
            _unitOfWork.AnalysisResults.Remove(row);
        }

        var freshRows = new List<AnalysisResult>();
        var centipawnLossByMove = new Dictionary<int, double>();
        for (var index = 0; index < moves.Count; index++)
        {
            var move = moves[index];
            var fenBeforeMove = index == 0 ? game.StartFen : moves[index - 1].FenAfterMove;

            var bestAnalysis = await _stockfish.AnalyzePositionAsync(fenBeforeMove);
            var playedAnalysis = await _stockfish.AnalyzePositionAsync(move.FenAfterMove);

            var bestEvaluationCp = bestAnalysis.EvaluationCp;
            var playedEvaluationCp = -playedAnalysis.EvaluationCp;
            var centipawnLoss = Math.Max(0, bestEvaluationCp - playedEvaluationCp);
            centipawnLossByMove[move.MoveNumber] = centipawnLoss;

            var row = new AnalysisResult
            {
                Id = Guid.NewGuid(),
                GameId = game.Id,
                MoveNumber = move.MoveNumber,
                BestMove = bestAnalysis.BestMove,
                PlayedMove = move.San,
                Evaluation = Math.Round(playedEvaluationCp / 100.0, 2),
                Classification = ClassifyMove(centipawnLoss),
            };

            freshRows.Add(row);
            await _unitOfWork.AnalysisResults.AddAsync(row);
        }

        await _unitOfWork.SaveChangesAsync();
        return BuildDto(game, moves, freshRows, centipawnLossByMove);
    }

    private async Task<Game> RequireAccessibleGameAsync(Guid gameId, Guid userId)
    {
        var game = await _unitOfWork.Games.GetByIdAsync(gameId)
            ?? throw new KeyNotFoundException("Oyun bulunamadi.");
        if (game.WhitePlayerId != userId && game.BlackPlayerId != userId)
        {
            throw new UnauthorizedAccessException("Bu oyuna erisemezsiniz.");
        }

        return game;
    }

    private static GameAnalysisDto BuildDto(
        Game game,
        IReadOnlyList<GameMove> moves,
        IReadOnlyCollection<AnalysisResult> analysisRows,
        IReadOnlyDictionary<int, double>? centipawnLossByMove = null)
    {
        var analysisByMove = analysisRows.ToDictionary(a => a.MoveNumber);
        var moveDtos = new List<MoveAnalysisDto>(moves.Count);

        for (var index = 0; index < moves.Count; index++)
        {
            var move = moves[index];
            if (!analysisByMove.TryGetValue(move.MoveNumber, out var analysis))
            {
                continue;
            }

            moveDtos.Add(new MoveAnalysisDto
            {
                MoveNumber = move.MoveNumber,
                San = move.San,
                FenBeforeMove = index == 0 ? game.StartFen : moves[index - 1].FenAfterMove,
                FenAfterMove = move.FenAfterMove,
                BestMove = analysis.BestMove,
                PlayedMove = analysis.PlayedMove,
                Evaluation = analysis.Evaluation,
                CentipawnLoss = centipawnLossByMove != null &&
                    centipawnLossByMove.TryGetValue(move.MoveNumber, out var cpl)
                    ? Math.Round(cpl, 0)
                    : 0,
                Classification = analysis.Classification,
            });
        }

        return new GameAnalysisDto
        {
            GameId = game.Id,
            Result = game.Result,
            MoveCount = moves.Count,
            Moves = moveDtos,
        };
    }

    private static AnalysisClassification ClassifyMove(double centipawnLoss)
    {
        if (centipawnLoss <= 15)
        {
            return AnalysisClassification.Best;
        }

        if (centipawnLoss <= 60)
        {
            return AnalysisClassification.Good;
        }

        if (centipawnLoss <= 120)
        {
            return AnalysisClassification.Inaccuracy;
        }

        if (centipawnLoss <= 250)
        {
            return AnalysisClassification.Mistake;
        }

        return AnalysisClassification.Blunder;
    }
}
