using EduCoach.API.Data;
using EduCoach.API.DTOs.Progress;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Services;

public sealed class ProgressService(AppDbContext dbContext)
{
    public async Task<ProgressSummaryResponse> GetSummaryAsync(Guid userId)
    {
        var topics = await dbContext.UserProgress
            .AsNoTracking()
            .Include(progress => progress.Topic)
            .Where(progress => progress.UserId == userId)
            .OrderBy(progress => progress.TopicId)
            .Select(progress => new TopicProgressResponse
            {
                TopicId = progress.TopicId,
                TopicName = progress.Topic!.Name,
                CurrentLevel = progress.CurrentLevel,
                TotalCorrect = progress.TotalCorrect,
                TotalAttempts = progress.TotalAttempts,
                AccuracyPercentage = progress.TotalAttempts == 0
                    ? 0
                    : Math.Round((double)progress.TotalCorrect / progress.TotalAttempts * 100, 2),
                StreakDays = progress.StreakDays
            })
            .ToListAsync();

        return new ProgressSummaryResponse { Topics = topics };
    }
}
