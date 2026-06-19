namespace EduCoach.API.DTOs.Practice;

public sealed class TopicSummaryResponse
{
    public required int Id { get; init; }
    public required string Name { get; init; }
    public required string Description { get; init; }
    public required string IconName { get; init; }
}
