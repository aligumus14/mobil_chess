using System.Security.Claims;
using ChessApp.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChessApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MatchmakingController : ControllerBase
{
    private readonly IMatchmakingService _matchmaking;

    public MatchmakingController(IMatchmakingService matchmaking)
    {
        _matchmaking = matchmaking;
    }

    [HttpPost("join")]
    public async Task<IActionResult> Join()
    {
        var userId = GetCurrentUserId();
        var result = await _matchmaking.JoinQueueAsync(userId);
        return Ok(result);
    }

    [HttpPost("leave")]
    public async Task<IActionResult> Leave()
    {
        var userId = GetCurrentUserId();
        var removed = await _matchmaking.LeaveQueueAsync(userId);
        return Ok(new { removed });
    }

    [HttpGet("status")]
    [HttpPost("status")]
    public async Task<IActionResult> Status()
    {
        var userId = GetCurrentUserId();
        var status = await _matchmaking.GetStatusAsync(userId);
        return Ok(status);
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(userIdClaim!);
    }
}
