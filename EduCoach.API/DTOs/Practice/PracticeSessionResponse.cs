namespace EduCoach.API.DTOs.Practice;

public sealed class PracticeSessionResponse
{
    public required Guid SessionId { get; init; }
    public required int TopicId { get; init; }
    public required string TopicName { get; init; }
    public required int DifficultyLevel { get; init; }
    public required List<PracticeQuestionResponse> Questions { get; init; }
}

public sealed class PracticeQuestionResponse
{
    public required Guid Id { get; init; }
    public required string Statement { get; init; }
    public required string OptionA { get; init; }
    public required string OptionB { get; init; }
    public required string OptionC { get; init; }
    public required string OptionD { get; init; }
    public string? Hint { get; init; }
}
