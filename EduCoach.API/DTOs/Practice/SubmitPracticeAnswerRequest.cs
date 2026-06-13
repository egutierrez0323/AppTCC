namespace EduCoach.API.DTOs.Practice;

public sealed class SubmitPracticeAnswerRequest
{
    public Guid SessionId { get; init; }
    public Guid QuestionId { get; init; }
    public string SelectedOption { get; init; } = string.Empty;
    public int ResponseTimeSeconds { get; init; }
}
