using EduCoach.API.Data;
using EduCoach.API.DTOs.Diagnostic;
using EduCoach.API.Models;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Services;

public sealed class DiagnosticService(AppDbContext dbContext)
{
    public async Task<IReadOnlyList<DiagnosticQuestionResponse>> GetQuestionsAsync()
    {
        return await dbContext.Questions
            .AsNoTracking()
            .Include(question => question.Topic)
            .Where(question => question.IsDiagnostic)
            .OrderBy(question => question.TopicId)
            .ThenBy(question => question.DifficultyLevel)
            .Select(question => new DiagnosticQuestionResponse
            {
                Id = question.Id,
                TopicId = question.TopicId,
                TopicName = question.Topic!.Name,
                DifficultyLevel = question.DifficultyLevel,
                Statement = question.Statement,
                OptionA = question.OptionA,
                OptionB = question.OptionB,
                OptionC = question.OptionC,
                OptionD = question.OptionD,
                Hint = question.Hint
            })
            .ToListAsync();
    }

    public async Task<SubmitDiagnosticResponse> SubmitAsync(Guid userId, SubmitDiagnosticRequest request)
    {
        var questionIds = request.Answers.Select(answer => answer.QuestionId).Distinct().ToList();
        var questions = await dbContext.Questions
            .Include(question => question.Topic)
            .Where(question => question.IsDiagnostic && questionIds.Contains(question.Id))
            .ToListAsync();

        if (questions.Count == 0)
        {
            throw new InvalidOperationException("No se recibieron respuestas validas para el diagnostico.");
        }

        var groupedResults = questions
            .GroupJoin(
                request.Answers,
                question => question.Id,
                answer => answer.QuestionId,
                (question, answers) => new
                {
                    Question = question,
                    SelectedOption = answers.FirstOrDefault()?.SelectedOption?.Trim().ToUpperInvariant() ?? string.Empty
                })
            .GroupBy(item => new { item.Question.TopicId, TopicName = item.Question.Topic!.Name })
            .Select(group =>
            {
                var total = group.Count();
                var score = group.Count(item => item.Question.CorrectOption.Equals(item.SelectedOption, StringComparison.OrdinalIgnoreCase));
                var assignedLevel = score switch
                {
                    <= 2 => 1,
                    <= 4 => 2,
                    _ => 3
                };

                return new DiagnosticTopicResultResponse
                {
                    TopicId = group.Key.TopicId,
                    TopicName = group.Key.TopicName,
                    Score = score,
                    TotalQuestions = total,
                    AssignedLevel = assignedLevel
                };
            })
            .ToList();

        var existingResults = await dbContext.DiagnosticResults.Where(result => result.UserId == userId).ToListAsync();
        dbContext.DiagnosticResults.RemoveRange(existingResults);

        foreach (var result in groupedResults)
        {
            dbContext.DiagnosticResults.Add(new DiagnosticResult
            {
                UserId = userId,
                TopicId = result.TopicId,
                Score = result.Score,
                TotalQuestions = result.TotalQuestions,
                AssignedLevel = result.AssignedLevel
            });

            var progress = await dbContext.UserProgress.FirstOrDefaultAsync(entry => entry.UserId == userId && entry.TopicId == result.TopicId);
            if (progress is null)
            {
                dbContext.UserProgress.Add(new UserProgress
                {
                    UserId = userId,
                    TopicId = result.TopicId,
                    CurrentLevel = result.AssignedLevel,
                    UpdatedAt = DateTime.UtcNow
                });
            }
            else
            {
                progress.CurrentLevel = result.AssignedLevel;
                progress.UpdatedAt = DateTime.UtcNow;
            }
        }

        await dbContext.SaveChangesAsync();

        return new SubmitDiagnosticResponse { Results = groupedResults };
    }
}
