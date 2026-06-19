using EduCoach.API.Data;
using EduCoach.API.DTOs.Practice;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Controllers;

[ApiController]
[Authorize]
[Route("topics")]
public sealed class TopicsController(AppDbContext dbContext) : ControllerBase
{
    private const int MixedTopicId = 99;

    [HttpGet]
    [ProducesResponseType<List<TopicSummaryResponse>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<List<TopicSummaryResponse>>> GetTopics(CancellationToken cancellationToken)
    {
        var topics = await dbContext.Topics
            .AsNoTracking()
            .Where(topic => topic.Id != MixedTopicId)
            .OrderBy(topic => topic.Id)
            .Select(topic => new TopicSummaryResponse
            {
                Id = topic.Id,
                Name = topic.Name,
                Description = topic.Description,
                IconName = topic.IconName
            })
            .ToListAsync(cancellationToken);

        return Ok(topics);
    }
}
