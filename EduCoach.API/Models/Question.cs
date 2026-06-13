namespace EduCoach.API.Models;

public sealed class Question
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public int TopicId { get; set; }
    public int DifficultyLevel { get; set; }
    public string Statement { get; set; } = string.Empty;
    public string OptionA { get; set; } = string.Empty;
    public string OptionB { get; set; } = string.Empty;
    public string OptionC { get; set; } = string.Empty;
    public string OptionD { get; set; } = string.Empty;
    public string CorrectOption { get; set; } = string.Empty;
    public string? Hint { get; set; }
    public bool IsDiagnostic { get; set; }
    public Topic? Topic { get; set; }
    public List<UserResponse> UserResponses { get; set; } = [];
}
