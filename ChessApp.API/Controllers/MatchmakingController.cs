using System.Security.Claims;
using ChessApp.Application.DTOs;
using ChessApp.Application.Services;
using ChessApp.Core.Enums;
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
    public async Task<IActionResult> Join([FromBody] JoinQueueRequestDto? request)
    {
        var userId = GetCurrentUserId();
        var tc = request != null && Enum.IsDefined(typeof(OnlineTimeControl), request.TimeControl)
            ? (OnlineTimeControl)request.TimeControl
            : OnlineTimeControl.Blitz5;
        var result = await _matchmaking.JoinQueueAsync(userId, tc);
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

    [HttpPost("abandon")]
    public async Task<IActionResult> Abandon()
    {
        var userId = GetCurrentUserId();
        var abandoned = await _matchmaking.AbandonActiveSessionAsync(userId);
        return Ok(new { abandoned });
    }

    /// Debug-only: returns every queue row so we can see why matches aren't forming.
    [HttpGet("debug-queue")]
    public async Task<IActionResult> DebugQueue([FromServices] ChessApp.Core.Interfaces.IUnitOfWork uow)
    {
        var all = await uow.MatchQueues.GetAllAsync();
        var rows = all.Select(q => new
        {
            q.Id,
            q.UserId,
            q.EloSnapshot,
            q.QueuedAt,
            Status = q.Status.ToString(),
            TimeControl = q.TimeControl.ToString(),
            TimeControlValue = (int)q.TimeControl,
        });
        return Ok(rows);
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(userIdClaim!);
    }
}
