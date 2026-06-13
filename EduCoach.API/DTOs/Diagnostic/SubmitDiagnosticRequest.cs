namespace EduCoach.API.DTOs.Diagnostic;

public sealed class SubmitDiagnosticRequest
{
    public List<DiagnosticAnswerRequest> Answers { get; init; } = [];
}

public sealed class DiagnosticAnswerRequest
{
    public Guid QuestionId { get; init; }
    public string SelectedOption { get; init; } = string.Empty;
}
