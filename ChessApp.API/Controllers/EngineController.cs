using ChessApp.Application.DTOs;
using ChessApp.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChessApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class EngineController : ControllerBase
{
    private readonly IStockfishService _stockfish;

    public EngineController(IStockfishService stockfish)
    {
        _stockfish = stockfish;
    }

    [HttpPost("best-move")]
    public async Task<IActionResult> GetBestMove([FromBody] BestMoveRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Fen))
        {
            return BadRequest(new { message = "FEN zorunludur." });
        }

        var moveTimeMs = dto.MoveTimeMs ?? ResolveMoveTime(dto.Difficulty);
        var result = await _stockfish.GetBestMoveAsync(
            dto.Fen,
            moveTimeMs: moveTimeMs,
            depth: dto.Depth);

        return Ok(new BestMoveResponseDto
        {
            BestMove = result.BestMove,
            Evaluation = Math.Round(result.EvaluationCp / 100.0, 2),
            MoveTimeMs = moveTimeMs,
            Depth = dto.Depth,
        });
    }

    private static int ResolveMoveTime(string? difficulty)
    {
        return difficulty?.Trim().ToLowerInvariant() switch
        {
            "easy" => 300,
            "hard" => 1500,
            _ => 800,
        };
    }
}
