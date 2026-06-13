namespace EduCoach.API.Models;

public sealed class Topic
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string IconName { get; set; } = string.Empty;
    public List<Question> Questions { get; set; } = [];
    public List<DiagnosticResult> DiagnosticResults { get; set; } = [];
    public List<PracticeSession> PracticeSessions { get; set; } = [];
    public List<UserProgress> ProgressEntries { get; set; } = [];
}
