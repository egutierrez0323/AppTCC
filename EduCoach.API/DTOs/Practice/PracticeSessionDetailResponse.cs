namespace EduCoach.API.DTOs.Practice;

public sealed class PracticeSessionDetailResponse
{
    public required Guid SessionId { get; init; }
    public required int TopicId { get; init; }
    public required string TopicName { get; init; }
    public required int DifficultyLevel { get; init; }
    public required int CorrectCount { get; init; }
    public required int TotalCount { get; init; }
    public required DateTime StartedAtUtc { get; init; }
    public DateTime? EndedAtUtc { get; init; }
    public List<PracticeSessionAnswerResponse> Answers { get; init; } = [];
}

public sealed class PracticeSessionAnswerResponse
{
    public required Guid QuestionId { get; init; }
    public required string Statement { get; init; }
    public required string SelectedOption { get; init; }
    public required string CorrectOption { get; init; }
    public required bool IsCorrect { get; init; }
    public string? AiExplanation { get; init; }
    public required DateTime AnsweredAtUtc { get; init; }
}

