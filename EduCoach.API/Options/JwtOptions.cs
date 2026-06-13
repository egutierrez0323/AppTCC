namespace EduCoach.API.Options;

public sealed class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; init; } = "EduCoach";
    public string Audience { get; init; } = "EduCoach.Mobile";
    public string SecretKey { get; init; } = "ChangeThisDevelopmentKeyForEduCoach123!";
    public int ExpirationHours { get; init; } = 24;
}
