using System.Security.Claims;
using EduCoach.API.DTOs.Diagnostic;
using EduCoach.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EduCoach.API.Controllers;

[ApiController]
[Authorize]
[Route("diagnostic")]
public sealed class DiagnosticController(DiagnosticService diagnosticService) : ControllerBase
{
    [HttpGet("questions")]
    [ProducesResponseType<IReadOnlyList<DiagnosticQuestionResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<IReadOnlyList<DiagnosticQuestionResponse>>> GetQuestions()
    {
        var questions = await diagnosticService.GetQuestionsAsync();
        return Ok(questions);
    }

    [HttpPost("submit")]
    [ProducesResponseType<SubmitDiagnosticResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<SubmitDiagnosticResponse>> Submit([FromBody] SubmitDiagnosticRequest request)
    {
        if (request.Answers.Count == 0)
        {
            return BadRequest(new { message = "Debes responder al menos una pregunta." });
        }

        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!Guid.TryParse(userIdValue, out var userId))
        {
            return Unauthorized(new { message = "No fue posible identificar el usuario autenticado." });
        }

        try
        {
            var response = await diagnosticService.SubmitAsync(userId, request);
            return Ok(response);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }
}
