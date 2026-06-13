namespace EduCoach.API.DTOs.Practice;

public sealed class SubmitPracticeAnswerResponse
{
    public required bool Correct { get; init; }
    public required string CorrectOption { get; init; }
    public string? Explanation { get; init; }
    public required int SessionCorrectCount { get; init; }
    public required int SessionTotalCount { get; init; }
    public required int CurrentLevel { get; init; }
    public required int StreakDays { get; init; }
    public required bool SessionCompleted { get; init; }
}
