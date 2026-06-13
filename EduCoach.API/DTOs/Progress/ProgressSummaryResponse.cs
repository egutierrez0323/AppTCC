namespace EduCoach.API.DTOs.Progress;

public sealed class ProgressSummaryResponse
{
    public List<TopicProgressResponse> Topics { get; init; } = [];
}

public sealed class TopicProgressResponse
{
    public required int TopicId { get; init; }
    public required string TopicName { get; init; }
    public required int CurrentLevel { get; init; }
    public required int TotalCorrect { get; init; }
    public required int TotalAttempts { get; init; }
    public required double AccuracyPercentage { get; init; }
    public required int StreakDays { get; init; }
}
