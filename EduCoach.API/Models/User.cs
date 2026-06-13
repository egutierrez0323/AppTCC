namespace EduCoach.API.Models;

public sealed class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLogin { get; set; }
    public List<DiagnosticResult> DiagnosticResults { get; set; } = [];
    public List<PracticeSession> PracticeSessions { get; set; } = [];
    public List<UserProgress> ProgressEntries { get; set; } = [];
}
