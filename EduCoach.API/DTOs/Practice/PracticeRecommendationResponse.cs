namespace EduCoach.API.DTOs.Practice;

public sealed class PracticeRecommendationResponse
{
    public required int TopicId { get; init; }
    public required string TopicName { get; init; }
    public required int RecommendedLevel { get; init; }
}

