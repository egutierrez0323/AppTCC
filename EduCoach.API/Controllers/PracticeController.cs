using System.Security.Claims;
using EduCoach.API.DTOs.Practice;
using EduCoach.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EduCoach.API.Controllers;

[ApiController]
[Authorize]
[Route("practice")]
public sealed class PracticeController(PracticeService practiceService) : ControllerBase
{
    [HttpGet("questions")]
    [ProducesResponseType<PracticeSessionResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PracticeSessionResponse>> GetQuestions(
        [FromQuery] int topicId,
        [FromQuery] int level = 1,
        [FromQuery] string mode = "normal")
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new { message = "No fue posible identificar el usuario autenticado." });
        }

        if (topicId <= 0)
        {
            return BadRequest(new { message = "Debes indicar un tema valido." });
        }

        try
        {
            var response = await practiceService.StartSessionAsync(userId, topicId, level, mode, HttpContext.RequestAborted);
            return Ok(response);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPost("answer")]
    [ProducesResponseType<SubmitPracticeAnswerResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SubmitPracticeAnswerResponse>> SubmitAnswer([FromBody] SubmitPracticeAnswerRequest request)
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new { message = "No fue posible identificar el usuario autenticado." });
        }

        try
        {
            var response = await practiceService.SubmitAnswerAsync(userId, request, HttpContext.RequestAborted);
            return Ok(response);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("history")]
    [ProducesResponseType<PracticeHistoryResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<PracticeHistoryResponse>> GetHistory([FromQuery] int limit = 20)
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new { message = "No fue posible identificar el usuario autenticado." });
        }

        var response = await practiceService.GetHistoryAsync(userId, limit, HttpContext.RequestAborted);
        return Ok(response);
    }

    [HttpGet("sessions/{sessionId:guid}")]
    [ProducesResponseType<PracticeSessionDetailResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PracticeSessionDetailResponse>> GetSessionDetail([FromRoute] Guid sessionId)
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new { message = "No fue posible identificar el usuario autenticado." });
        }

        try
        {
            var response = await practiceService.GetSessionDetailAsync(userId, sessionId, HttpContext.RequestAborted);
            return Ok(response);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("recommendation")]
    [ProducesResponseType<PracticeRecommendationResponse>(StatusCodes.Status200OK)]
    public async Task<ActionResult<PracticeRecommendationResponse>> GetRecommendation()
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new { message = "No fue posible identificar el usuario autenticado." });
        }

        var response = await practiceService.GetRecommendationAsync(userId, HttpContext.RequestAborted);
        return Ok(response);
    }
}
