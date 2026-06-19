using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using EduCoach.API.Models;

namespace EduCoach.API.Services;

public sealed class DeepSeekService(HttpClient httpClient, IConfiguration configuration)
{
    private const string DefaultBaseUrl = "https://api.deepseek.com";
    private const string DefaultTone = "amable";
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = false };

    public async Task<string> GetExplanationAsync(Question question, string selectedOption, CancellationToken cancellationToken = default)
    {
        var apiKey = configuration["DeepSeek:ApiKey"];
        var baseUrl = configuration["DeepSeek:BaseUrl"];
        var model = configuration["DeepSeek:Model"] ?? "deepseek-chat";

        if (string.IsNullOrWhiteSpace(baseUrl))
        {
            baseUrl = DefaultBaseUrl;
        }

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            return BuildFallbackExplanationJson(question, selectedOption);
        }

        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl.TrimEnd('/')}/chat/completions");
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);
            request.Content = JsonContent.Create(new
            {
                model,
                temperature = 0.2,
                messages = new object[]
                {
                    new
                    {
                        role = "system",
                        content =
                            "Eres un tutor de matematicas para estudiantes de secundaria. " +
                            "Responde solo con JSON valido y sin texto adicional. " +
                            "El tono debe ser amable, claro, paciente y pedagogico. " +
                            "En los campos de texto no uses Markdown ni LaTeX. " +
                            "Las formulas deben ir solo en formulaLatex. " +
                            "Usa maximo 4 pasos."
                    },
                    new
                    {
                        role = "user",
                        content =
                            $"Pregunta: {question.Statement}\n" +
                            $"Respuesta del estudiante: {selectedOption}\n" +
                            $"Respuesta correcta: {question.CorrectOption}\n" +
                            $"Pista: {question.Hint ?? "No disponible"}\n" +
                            "Devuelve solo JSON con esta estructura exacta:\n" +
                            "{\n" +
                            "  \"version\": \"1.0\",\n" +
                            "  \"tone\": \"amable\",\n" +
                            "  \"summary\": \"...\",\n" +
                            "  \"steps\": [\n" +
                            "    {\n" +
                            "      \"title\": \"...\",\n" +
                            "      \"text\": \"...\",\n" +
                            "      \"formulaLatex\": \"...\"\n" +
                            "    }\n" +
                            "  ],\n" +
                            "  \"finalAnswerText\": \"...\",\n" +
                            "  \"encouragement\": \"...\"\n" +
                            "}\n" +
                            "Si no necesitas formula en un paso, usa cadena vacia."
                    }
                }
            });

            using var response = await httpClient.SendAsync(request, cancellationToken);
            response.EnsureSuccessStatusCode();

            var body = await response.Content.ReadFromJsonAsync<JsonObject>(cancellationToken: cancellationToken);
            var content = body?["choices"]?[0]?["message"]?["content"]?.GetValue<string>();
            return TryNormalizeStructuredExplanation(content)
                ?? BuildFallbackExplanationJson(question, selectedOption);
        }
        catch
        {
            return BuildFallbackExplanationJson(question, selectedOption);
        }
    }

    private static string? TryNormalizeStructuredExplanation(string? content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return null;
        }

        var trimmed = content.Trim();
        if (trimmed.StartsWith("```", StringComparison.Ordinal))
        {
            var firstLineBreak = trimmed.IndexOf('\n');
            if (firstLineBreak >= 0)
            {
                trimmed = trimmed[(firstLineBreak + 1)..];
            }

            if (trimmed.EndsWith("```", StringComparison.Ordinal))
            {
                trimmed = trimmed[..^3].TrimEnd();
            }
        }

        JsonObject? parsed;
        try
        {
            parsed = JsonNode.Parse(trimmed) as JsonObject;
        }
        catch
        {
            return null;
        }

        if (parsed is null)
        {
            return null;
        }

        var summary = parsed["summary"]?.GetValue<string>()?.Trim();
        var finalAnswerText = parsed["finalAnswerText"]?.GetValue<string>()?.Trim();
        var encouragement = parsed["encouragement"]?.GetValue<string>()?.Trim();
        var stepsNode = parsed["steps"] as JsonArray;

        if (string.IsNullOrWhiteSpace(summary) || string.IsNullOrWhiteSpace(finalAnswerText))
        {
            return null;
        }

        var normalizedSteps = new JsonArray();
        if (stepsNode is not null)
        {
            foreach (var item in stepsNode)
            {
                if (item is not JsonObject stepObject)
                {
                    continue;
                }

                var title = stepObject["title"]?.GetValue<string>()?.Trim();
                var text = stepObject["text"]?.GetValue<string>()?.Trim();
                var formulaLatex = stepObject["formulaLatex"]?.GetValue<string>()?.Trim() ?? string.Empty;

                if (string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(text))
                {
                    continue;
                }

                normalizedSteps.Add(new JsonObject
                {
                    ["title"] = title,
                    ["text"] = text,
                    ["formulaLatex"] = formulaLatex
                });
            }
        }

        var normalized = new JsonObject
        {
            ["version"] = "1.0",
            ["tone"] = parsed["tone"]?.GetValue<string>()?.Trim() ?? DefaultTone,
            ["summary"] = summary,
            ["steps"] = normalizedSteps,
            ["finalAnswerText"] = finalAnswerText,
            ["encouragement"] = encouragement ?? string.Empty
        };

        return normalized.ToJsonString(JsonOptions);
    }

    private static string BuildFallbackExplanationJson(Question question, string selectedOption)
    {
        var normalizedSelectedOption = selectedOption.Trim().ToUpperInvariant();
        var root = new JsonObject
        {
            ["version"] = "1.0",
            ["tone"] = DefaultTone,
            ["summary"] = $"La opcion {normalizedSelectedOption} no es correcta.",
            ["steps"] = new JsonArray
            {
                new JsonObject
                {
                    ["title"] = "Respuesta correcta",
                    ["text"] = $"La respuesta correcta es {question.CorrectOption}.",
                    ["formulaLatex"] = string.Empty
                },
                new JsonObject
                {
                    ["title"] = "Pista",
                    ["text"] = question.Hint ?? "Revisa el procedimiento paso a paso y vuelve a intentarlo.",
                    ["formulaLatex"] = string.Empty
                }
            },
            ["finalAnswerText"] = $"Debes elegir la opcion {question.CorrectOption}.",
            ["encouragement"] = "Sigue practicando, vas por buen camino."
        };

        return root.ToJsonString(JsonOptions);
    }
}
