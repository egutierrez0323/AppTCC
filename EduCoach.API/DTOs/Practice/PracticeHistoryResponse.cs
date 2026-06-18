namespace EduCoach.API.DTOs.Practice;

public sealed class PracticeHistoryResponse
{
    public List<PracticeSessionSummaryResponse> Sessions { get; init; } = [];
}

public sealed class PracticeSessionSummaryResponse
{
    public required Guid SessionId { get; init; }
    public required int TopicId { get; init; }
    public required string TopicName { get; init; }
    public required int DifficultyLevel { get; init; }
    public required int CorrectCount { get; init; }
    public required int TotalCount { get; init; }
    public required DateTime StartedAtUtc { get; init; }
    public DateTime? EndedAtUtc { get; init; }
}

