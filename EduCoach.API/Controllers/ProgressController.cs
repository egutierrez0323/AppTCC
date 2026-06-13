using System.Security.Claims;
using EduCoach.API.DTOs.Progress;
using EduCoach.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EduCoach.API.Controllers;

[ApiController]
[Authorize]
[Route("progress")]
public sealed class ProgressController(ProgressService progressService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<ProgressSummaryResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<ProgressSummaryResponse>> GetSummary()
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new { message = "No fue posible identificar el usuario autenticado." });
        }

        var response = await progressService.GetSummaryAsync(userId);
        return Ok(response);
    }
}
