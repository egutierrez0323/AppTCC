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
            .OrderBy(question => question.Statement)
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
}
