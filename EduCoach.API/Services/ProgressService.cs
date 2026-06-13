using EduCoach.API.Data;
using EduCoach.API.DTOs.Progress;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Services;

public sealed class ProgressService(AppDbContext dbContext)
{
    public async Task<ProgressSummaryResponse> GetSummaryAsync(Guid userId)
    {
        var progressEntries = await dbContext.UserProgress
            .AsNoTracking()
            .Include(progress => progress.Topic)
            .Where(progress => progress.UserId == userId)
            .OrderBy(progress => progress.TopicId)
            .ToListAsync();

        var topics = progressEntries
            .Select(progress => new TopicProgressResponse
            {
                TopicId = progress.TopicId,
                TopicName = progress.Topic?.Name ?? "Tema",
                CurrentLevel = progress.CurrentLevel,
                TotalCorrect = progress.TotalCorrect,
                TotalAttempts = progress.TotalAttempts,
                AccuracyPercentage = progress.TotalAttempts == 0
                    ? 0
                    : Math.Round((double)progress.TotalCorrect / progress.TotalAttempts * 100, 2),
                StreakDays = progress.StreakDays
            })
            .ToList();

        return new ProgressSummaryResponse { Topics = topics };
    }
}
