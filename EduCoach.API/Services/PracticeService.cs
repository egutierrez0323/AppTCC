using EduCoach.API.Data;
using EduCoach.API.DTOs.Practice;
using EduCoach.API.Models;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Services;

public sealed class PracticeService(AppDbContext dbContext, DeepSeekService deepSeekService)
{
    private const int DefaultSessionQuestionCount = 5;
    private const int MixedTopicId = 99;
    private const string NormalMode = "normal";
    private const string ReviewMode = "review";
    private const string MixedMode = "mixed";

    public async Task<PracticeSessionResponse> StartSessionAsync(
        Guid userId,
        int topicId,
        int level,
        string? mode,
        CancellationToken cancellationToken = default)
    {
        var sanitizedLevel = Math.Clamp(level, 1, 3);
        var sanitizedMode = NormalizeMode(mode);
        var actualMode = sanitizedMode;
        string? modeMessage = null;
        Topic topic;
        List<(Question question, bool wasFailedBefore)> questions;

        if (sanitizedMode == MixedMode)
        {
            topic = await dbContext.Topics.AsNoTracking().FirstOrDefaultAsync(
                    item => item.Id == MixedTopicId,
                    cancellationToken)
                ?? throw new InvalidOperationException("No fue posible preparar la practica mixta.");
            questions = await GetMixedQuestionsAsync(sanitizedLevel, cancellationToken);
        }
        else
        {
            topic = await dbContext.Topics.AsNoTracking().FirstOrDefaultAsync(
                    item => item.Id == topicId,
                    cancellationToken)
                ?? throw new InvalidOperationException("El tema seleccionado no existe.");
            questions = sanitizedMode == ReviewMode
                ? await GetReviewQuestionsAsync(userId, topicId, sanitizedLevel, cancellationToken)
                : await GetNormalQuestionsAsync(topicId, sanitizedLevel, cancellationToken: cancellationToken);
        }

        if (questions.Count == 0)
        {
            throw new InvalidOperationException(
                sanitizedMode == MixedMode
                    ? "No hay preguntas suficientes para la practica mixta en ese nivel."
                    : "No hay preguntas de practica disponibles para ese tema y nivel.");
        }

        if (sanitizedMode == ReviewMode && !questions.Any(question => question.wasFailedBefore))
        {
            actualMode = NormalMode;
            modeMessage = "Aun no tienes errores previos en este tema y nivel. Se inicio una practica normal.";
        }

        var session = new PracticeSession
        {
            UserId = userId,
            TopicId = topic.Id,
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
            Mode = actualMode,
            ModeMessage = modeMessage,
            Questions = questions.Select(question => new PracticeQuestionResponse
            {
                Id = question.question.Id,
                Statement = question.question.Statement,
                OptionA = question.question.OptionA,
                OptionB = question.question.OptionB,
                OptionC = question.question.OptionC,
                OptionD = question.question.OptionD,
                Hint = question.question.Hint
            }).ToList()
        };
    }

    private static string NormalizeMode(string? mode)
    {
        var normalized = mode?.Trim().ToLowerInvariant();
        return normalized switch
        {
            ReviewMode => ReviewMode,
            MixedMode => MixedMode,
            _ => NormalMode
        };
    }

    private async Task<List<(Question question, bool wasFailedBefore)>> GetNormalQuestionsAsync(
        int topicId,
        int level,
        IReadOnlyCollection<Guid>? excludedQuestionIds = null,
        CancellationToken cancellationToken = default)
    {
        var excludedIds = excludedQuestionIds ?? Array.Empty<Guid>();
        var questions = await dbContext.Questions
            .AsNoTracking()
            .Where(question =>
                !question.IsDiagnostic &&
                question.TopicId == topicId &&
                question.DifficultyLevel == level &&
                !excludedIds.Contains(question.Id))
            .OrderBy(_ => Guid.NewGuid())
            .Take(DefaultSessionQuestionCount)
            .ToListAsync(cancellationToken);

        return questions
            .Select(question => (question, wasFailedBefore: false))
            .ToList();
    }

    private async Task<List<(Question question, bool wasFailedBefore)>> GetReviewQuestionsAsync(
        Guid userId,
        int topicId,
        int level,
        CancellationToken cancellationToken = default)
    {
        var failedQuestionIds = await dbContext.UserResponses
            .AsNoTracking()
            .Include(response => response.Session)
            .Where(response =>
                !response.IsCorrect &&
                response.Session != null &&
                response.Session.UserId == userId &&
                response.Session.TopicId == topicId &&
                response.Session.DifficultyLevel == level)
            .OrderByDescending(response => response.AnsweredAt)
            .Select(response => response.QuestionId)
            .Distinct()
            .Take(DefaultSessionQuestionCount)
            .ToListAsync(cancellationToken);

        var reviewedQuestions = failedQuestionIds.Count == 0
            ? []
            : await dbContext.Questions
                .AsNoTracking()
                .Where(question => !question.IsDiagnostic && failedQuestionIds.Contains(question.Id))
                .ToListAsync(cancellationToken);

        var reviewedLookup = reviewedQuestions.ToDictionary(question => question.Id);
        var orderedReviewQuestions = failedQuestionIds
            .Where(reviewedLookup.ContainsKey)
            .Select(id => (question: reviewedLookup[id], wasFailedBefore: true))
            .ToList();

        if (orderedReviewQuestions.Count >= DefaultSessionQuestionCount)
        {
            return orderedReviewQuestions;
        }

        var fillerQuestions = await GetNormalQuestionsAsync(
            topicId,
            level,
            orderedReviewQuestions.Select(item => item.question.Id).ToArray(),
            cancellationToken);

        return orderedReviewQuestions
            .Concat(fillerQuestions.Take(DefaultSessionQuestionCount - orderedReviewQuestions.Count))
            .ToList();
    }

    private async Task<List<(Question question, bool wasFailedBefore)>> GetMixedQuestionsAsync(
        int level,
        CancellationToken cancellationToken = default)
    {
        var availableQuestions = await dbContext.Questions
            .AsNoTracking()
            .Where(question =>
                !question.IsDiagnostic &&
                question.TopicId != MixedTopicId &&
                question.DifficultyLevel == level)
            .ToListAsync(cancellationToken);

        if (availableQuestions.Count == 0)
        {
            return [];
        }

        var prioritizedQuestions = availableQuestions
            .GroupBy(question => question.TopicId)
            .Select(group => group.OrderBy(_ => Guid.NewGuid()).First())
            .OrderBy(_ => Guid.NewGuid())
            .Take(DefaultSessionQuestionCount)
            .ToList();

        if (prioritizedQuestions.Count < DefaultSessionQuestionCount)
        {
            var selectedIds = prioritizedQuestions.Select(question => question.Id).ToHashSet();
            var fillerQuestions = availableQuestions
                .Where(question => !selectedIds.Contains(question.Id))
                .OrderBy(_ => Guid.NewGuid())
                .Take(DefaultSessionQuestionCount - prioritizedQuestions.Count);

            prioritizedQuestions.AddRange(fillerQuestions);
        }

        return prioritizedQuestions
            .Take(DefaultSessionQuestionCount)
            .Select(question => (question, wasFailedBefore: false))
            .ToList();
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

        var isMixedSession = session.TopicId == MixedTopicId;
        var question = await dbContext.Questions
            .AsNoTracking()
            .FirstOrDefaultAsync(item =>
                item.Id == request.QuestionId &&
                item.DifficultyLevel == session.DifficultyLevel &&
                (isMixedSession ? item.TopicId != MixedTopicId : item.TopicId == session.TopicId) &&
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
            item => item.UserId == userId && item.TopicId == question.TopicId, cancellationToken);

        if (progress is null)
        {
            progress = new UserProgress
            {
                UserId = userId,
                TopicId = question.TopicId,
                CurrentLevel = session.DifficultyLevel
            };
            dbContext.UserProgress.Add(progress);
        }

        progress.TotalAttempts++;
        if (isCorrect)
        {
            progress.TotalCorrect++;
        }

        if (!isMixedSession && session.ConsecutiveCorrectCount >= 3)
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
            CurrentLevel = isMixedSession ? session.DifficultyLevel : progress.CurrentLevel,
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
