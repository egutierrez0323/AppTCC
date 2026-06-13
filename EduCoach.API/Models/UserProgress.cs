namespace EduCoach.API.Models;

public sealed class UserProgress
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int TopicId { get; set; }
    public int CurrentLevel { get; set; } = 1;
    public int TotalCorrect { get; set; }
    public int TotalAttempts { get; set; }
    public int StreakDays { get; set; }
    public DateOnly? LastPracticeDate { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public User? User { get; set; }
    public Topic? Topic { get; set; }
}
