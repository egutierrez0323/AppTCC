using EduCoach.API.Data;
using EduCoach.API.DTOs.Practice;
using EduCoach.API.Models;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Services;

public sealed class PracticeService(AppDbContext dbContext, DeepSeekService deepSeekService)
{
    private const int DefaultSessionQuestionCount = 5;

    public async Task<PracticeSessionResponse> StartSessionAsync(Guid userId, int topicId, int level)
    {
        var topic = await dbContext.Topics.AsNoTracking().FirstOrDefaultAsync(item => item.Id == topicId)
            ?? throw new InvalidOperationException("El tema seleccionado no existe.");

        var sanitizedLevel = Math.Clamp(level, 1, 3);
        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(question => !question.IsDiagnostic && question.TopicId == topicId && question.DifficultyLevel == sanitizedLevel)
            .OrderBy(_ => Guid.NewGuid())
            .Take(DefaultSessionQuestionCount)
            .ToListAsync();

        if (questions.Count == 0)
        {
            throw new InvalidOperationException("No hay preguntas de practica disponibles para ese tema y nivel.");
        }

        var session = new PracticeSession
        {
            UserId = userId,
            TopicId = topicId,
            DifficultyLevel = sanitizedLevel,
            PlannedQuestionCount = questions.Count,
            StartedAt = DateTime.UtcNow
        };

        dbContext.PracticeSessions.Add(session);
        await dbContext.SaveChangesAsync();

        return new PracticeSessionResponse
        {
            SessionId = session.Id,
            TopicId = topic.Id,
            TopicName = topic.Name,
            DifficultyLevel = session.DifficultyLevel,
            Questions = questions.Select(question => new PracticeQuestionResponse
            {
                Id = question.Id,
                Statement = question.Statement,
                OptionA = question.OptionA,
                OptionB = question.OptionB,
                OptionC = question.OptionC,
                OptionD = question.OptionD,
                Hint = question.Hint
            }).ToList()
        };
    }

    public async Task<SubmitPracticeAnswerResponse> SubmitAnswerAsync(Guid userId, SubmitPracticeAnswerRequest request, CancellationToken cancellationToken = default)
    {
        var session = await dbContext.PracticeSessions
            .Include(item => item.Topic)
            .Include(item => item.Responses)
            .FirstOrDefaultAsync(item => item.Id == request.SessionId && item.UserId == userId, cancellationToken)
            ?? throw new InvalidOperationException("La sesion de practica no existe.");

        if (session.EndedAt is not null)
        {
            throw new InvalidOperationException("La sesion de practica ya fue completada.");
        }

        var selectedOption = request.SelectedOption.Trim().ToUpperInvariant();
        if (selectedOption is not ("A" or "B" or "C" or "D"))
        {
            throw new InvalidOperationException("La opcion seleccionada no es valida.");
        }

        var alreadyAnswered = session.Responses.Any(response => response.QuestionId == request.QuestionId);
        if (alreadyAnswered)
        {
            throw new InvalidOperationException("Esta pregunta ya fue respondida en la sesion actual.");
        }

        var question = await dbContext.Questions
            .AsNoTracking()
            .FirstOrDefaultAsync(item =>
                item.Id == request.QuestionId &&
                item.TopicId == session.TopicId &&
                item.DifficultyLevel == session.DifficultyLevel &&
                !item.IsDiagnostic, cancellationToken)
            ?? throw new InvalidOperationException("La pregunta enviada no pertenece a esta sesion.");

        var isCorrect = question.CorrectOption.Equals(selectedOption, StringComparison.OrdinalIgnoreCase);
        var explanation = isCorrect
            ? null
            : await deepSeekService.GetExplanationAsync(question, selectedOption, cancellationToken);

        dbContext.UserResponses.Add(new UserResponse
        {
            SessionId = session.Id,
            QuestionId = question.Id,
            SelectedOption = selectedOption,
            IsCorrect = isCorrect,
            AiExplanation = explanation,
            ResponseTimeSeconds = Math.Max(0, request.ResponseTimeSeconds),
            AnsweredAt = DateTime.UtcNow
        });

        session.TotalCount++;
        if (isCorrect)
        {
            session.CorrectCount++;
            session.ConsecutiveCorrectCount++;
        }
        else
        {
            session.ConsecutiveCorrectCount = 0;
        }

        if (session.TotalCount >= session.PlannedQuestionCount)
        {
            session.EndedAt = DateTime.UtcNow;
        }

        var progress = await dbContext.UserProgress.FirstOrDefaultAsync(
            item => item.UserId == userId && item.TopicId == session.TopicId, cancellationToken);

        if (progress is null)
        {
            progress = new UserProgress
            {
                UserId = userId,
                TopicId = session.TopicId,
                CurrentLevel = session.DifficultyLevel
            };
            dbContext.UserProgress.Add(progress);
        }

        progress.TotalAttempts++;
        if (isCorrect)
        {
            progress.TotalCorrect++;
        }

        if (session.ConsecutiveCorrectCount >= 3)
        {
            progress.CurrentLevel = Math.Min(3, progress.CurrentLevel + 1);
            session.ConsecutiveCorrectCount = 0;
        }

        UpdateStreak(progress);
        progress.UpdatedAt = DateTime.UtcNow;

        await dbContext.SaveChangesAsync(cancellationToken);

        return new SubmitPracticeAnswerResponse
        {
            Correct = isCorrect,
            CorrectOption = question.CorrectOption,
            Explanation = explanation,
            SessionCorrectCount = session.CorrectCount,
            SessionTotalCount = session.TotalCount,
            CurrentLevel = progress.CurrentLevel,
            StreakDays = progress.StreakDays,
            SessionCompleted = session.EndedAt is not null
        };
    }

    private static void UpdateStreak(UserProgress progress)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        if (progress.LastPracticeDate is null)
        {
            progress.StreakDays = 1;
        }
        else if (progress.LastPracticeDate == today)
        {
            progress.StreakDays = Math.Max(1, progress.StreakDays);
        }
        else if (progress.LastPracticeDate == today.AddDays(-1))
        {
            progress.StreakDays = Math.Max(1, progress.StreakDays) + 1;
        }
        else
        {
            progress.StreakDays = 1;
        }

        progress.LastPracticeDate = today;
    }

    public async Task<PracticeHistoryResponse> GetHistoryAsync(Guid userId, int limit = 20, CancellationToken cancellationToken = default)
    {
        var take = Math.Clamp(limit, 1, 100);
        var sessions = await dbContext.PracticeSessions
            .AsNoTracking()
            .Include(session => session.Topic)
            .Where(session => session.UserId == userId)
            .OrderByDescending(session => session.StartedAt)
            .Take(take)
            .Select(session => new PracticeSessionSummaryResponse
            {
                SessionId = session.Id,
                TopicId = session.TopicId,
                TopicName = session.Topic!.Name,
                DifficultyLevel = session.DifficultyLevel,
                CorrectCount = session.CorrectCount,
                TotalCount = session.TotalCount,
                StartedAtUtc = session.StartedAt,
                EndedAtUtc = session.EndedAt
            })
            .ToListAsync(cancellationToken);

        return new PracticeHistoryResponse { Sessions = sessions };
    }

    public async Task<PracticeSessionDetailResponse> GetSessionDetailAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken = default)
    {
        var session = await dbContext.PracticeSessions
            .AsNoTracking()
            .Include(item => item.Topic)
            .Include(item => item.Responses)
            .ThenInclude(response => response.Question)
            .FirstOrDefaultAsync(item => item.Id == sessionId && item.UserId == userId, cancellationToken)
            ?? throw new InvalidOperationException("La sesion de practica no existe.");

        var answers = session.Responses
            .OrderBy(response => response.AnsweredAt)
            .Select(response => new PracticeSessionAnswerResponse
            {
                QuestionId = response.QuestionId,
                Statement = response.Question?.Statement ?? string.Empty,
                SelectedOption = response.SelectedOption,
                CorrectOption = response.Question?.CorrectOption ?? string.Empty,
                IsCorrect = response.IsCorrect,
                AiExplanation = response.AiExplanation,
                AnsweredAtUtc = response.AnsweredAt
            })
            .ToList();

        return new PracticeSessionDetailResponse
        {
            SessionId = session.Id,
            TopicId = session.TopicId,
            TopicName = session.Topic?.Name ?? "Tema",
            DifficultyLevel = session.DifficultyLevel,
            CorrectCount = session.CorrectCount,
            TotalCount = session.TotalCount,
            StartedAtUtc = session.StartedAt,
            EndedAtUtc = session.EndedAt,
            Answers = answers
        };
    }

    public async Task<PracticeRecommendationResponse> GetRecommendationAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var progressEntries = await dbContext.UserProgress
            .AsNoTracking()
            .Include(progress => progress.Topic)
            .Where(progress => progress.UserId == userId)
            .ToListAsync(cancellationToken);

        if (progressEntries.Count == 0)
        {
            var firstTopic = await dbContext.Topics.AsNoTracking().OrderBy(topic => topic.Id).FirstOrDefaultAsync(cancellationToken);
            return new PracticeRecommendationResponse
            {
                TopicId = firstTopic?.Id ?? 1,
                TopicName = firstTopic?.Name ?? "Fracciones",
                RecommendedLevel = 1
            };
        }

        var selected = progressEntries
            .Select(progress => new
            {
                Progress = progress,
                Accuracy = progress.TotalAttempts == 0 ? 0 : (double)progress.TotalCorrect / progress.TotalAttempts
            })
            .OrderBy(item => item.Accuracy)
            .ThenBy(item => item.Progress.TotalAttempts)
            .First()
            .Progress;

        return new PracticeRecommendationResponse
        {
            TopicId = selected.TopicId,
            TopicName = selected.Topic?.Name ?? "Tema",
            RecommendedLevel = Math.Clamp(selected.CurrentLevel, 1, 3)
        };
    }
}
