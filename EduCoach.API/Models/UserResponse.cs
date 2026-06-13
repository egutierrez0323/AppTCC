namespace EduCoach.API.Models;

public sealed class UserResponse
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SessionId { get; set; }
    public Guid QuestionId { get; set; }
    public string SelectedOption { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
    public string? AiExplanation { get; set; }
    public int ResponseTimeSeconds { get; set; }
    public DateTime AnsweredAt { get; set; } = DateTime.UtcNow;
    public PracticeSession? Session { get; set; }
    public Question? Question { get; set; }
}
