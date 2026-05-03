using System.Security.Claims;
using ChessApp.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ChessApp.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AnalysisController : ControllerBase
{
    private readonly IGameAnalysisService _analysisService;

    public AnalysisController(IGameAnalysisService analysisService)
    {
        _analysisService = analysisService;
    }

    [HttpPost("game/{id:guid}")]
    public async Task<IActionResult> AnalyzeGame(Guid id, [FromQuery] bool force = false)
    {
        var userId = GetCurrentUserId();
        var result = await _analysisService.AnalyzeGameAsync(id, userId, force);
        return Ok(result);
    }

    [HttpGet("game/{id:guid}")]
    public async Task<IActionResult> GetGameAnalysis(Guid id)
    {
        var userId = GetCurrentUserId();
        var result = await _analysisService.GetGameAnalysisAsync(id, userId);
        if (result == null)
        {
            return NotFound(new { message = "Bu oyun icin kayitli analiz bulunamadi." });
        }

        return Ok(result);
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.Parse(userIdClaim!);
    }
}
