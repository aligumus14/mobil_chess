using System.Security.Claims;
using ChessApp.Application.DTOs;
using ChessApp.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChessApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class GamesController : ControllerBase
{
    private readonly IGameService _gameService;

    public GamesController(IGameService gameService)
    {
        _gameService = gameService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateGame([FromBody] CreateGameDto dto)
    {
        var userId = GetCurrentUserId();
        var id = await _gameService.CreateOfflineGameAsync(userId, dto);
        return CreatedAtAction(nameof(GetGameById), new { id }, new { id });
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyGames([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = GetCurrentUserId();
        var result = await _gameService.GetUserGamesAsync(userId, page, pageSize);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetGameById(Guid id)
    {
        var userId = GetCurrentUserId();
        var detail = await _gameService.GetGameDetailAsync(id, userId);
        if (detail == null)
        {
            return NotFound(new { message = "Oyun bulunamadi." });
        }

        return Ok(detail);
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(userIdClaim!);
    }
}
