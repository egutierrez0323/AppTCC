using System.Net.Http.Json;
using System.Text.Json.Nodes;
using EduCoach.API.Models;

namespace EduCoach.API.Services;

public sealed class DeepSeekService(HttpClient httpClient, IConfiguration configuration)
{
    public async Task<string> GetExplanationAsync(Question question, string selectedOption, CancellationToken cancellationToken = default)
    {
        var apiKey = configuration["DeepSeek:ApiKey"];
        var baseUrl = configuration["DeepSeek:BaseUrl"];
        var model = configuration["DeepSeek:Model"] ?? "deepseek-chat";

        if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(baseUrl))
        {
            return BuildFallbackExplanation(question, selectedOption);
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl.TrimEnd('/')}/chat/completions");
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
            request.Content = JsonContent.Create(new
            {
                model,
                messages = new object[]
                {
                    new
                    {
                        role = "system",
                        content = "Eres un tutor de matematicas para estudiantes de secundaria. Explica de forma breve, clara y amable."
                    },
                    new
                    {
                        role = "user",
                        content =
                            $"Pregunta: {question.Statement}\n" +
                            $"Respuesta del estudiante: {selectedOption}\n" +
                            $"Respuesta correcta: {question.CorrectOption}\n" +
                            $"Pista: {question.Hint ?? "No disponible"}\n" +
                            "Explica paso a paso como resolverla en maximo 150 palabras."
                    }
                }
            });

            using var response = await httpClient.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();

            var body = await response.Content.ReadFromJsonAsync<JsonObject>(cancellationToken: cancellationToken);
            var content = body?["choices"]?[0]?["message"]?["content"]?.GetValue<string>();
            return string.IsNullOrWhiteSpace(content)
                ? BuildFallbackExplanation(question, selectedOption)
                : content.Trim();
        }
        catch
        {
            return BuildFallbackExplanation(question, selectedOption);
        }
    }

    private static string BuildFallbackExplanation(Question question, string selectedOption)
    {
        return $"La opcion {selectedOption} no es correcta. La respuesta correcta es {question.CorrectOption}. " +
               $"{question.Hint ?? "Revisa el procedimiento paso a paso y vuelve a intentarlo."}";
    }
}
