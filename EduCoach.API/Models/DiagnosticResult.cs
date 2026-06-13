namespace EduCoach.API.Models;

public sealed class DiagnosticResult
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public int TopicId { get; set; }
    public int Score { get; set; }
    public int TotalQuestions { get; set; }
    public int AssignedLevel { get; set; }
    public DateTime TakenAt { get; set; } = DateTime.UtcNow;
    public User? User { get; set; }
    public Topic? Topic { get; set; }
}
