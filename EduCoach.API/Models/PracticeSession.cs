namespace EduCoach.API.Models;

public sealed class PracticeSession
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int TopicId { get; set; }
    public int DifficultyLevel { get; set; }
    public int CorrectCount { get; set; }
    public int TotalCount { get; set; }
    public int ConsecutiveCorrectCount { get; set; }
    public int PlannedQuestionCount { get; set; }
    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime? EndedAt { get; set; }
    public User? User { get; set; }
    public Topic? Topic { get; set; }
    public List<UserResponse> Responses { get; set; } = [];
}
