namespace EduCoach.API.DTOs.Auth;

public sealed class AuthResponse
{
    public required string Token { get; init; }
    public required DateTime ExpiresAtUtc { get; init; }
    public required UserSummaryResponse User { get; init; }
}

public sealed class UserSummaryResponse
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required string Email { get; init; }
}
