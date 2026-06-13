namespace EduCoach.API.DTOs.Diagnostic;

public sealed class SubmitDiagnosticResponse
{
    public List<DiagnosticTopicResultResponse> Results { get; init; } = [];
}

public sealed class DiagnosticTopicResultResponse
{
    public required int TopicId { get; init; }
    public required string TopicName { get; init; }
    public required int Score { get; init; }
    public required int TotalQuestions { get; init; }
    public required int AssignedLevel { get; init; }
}
