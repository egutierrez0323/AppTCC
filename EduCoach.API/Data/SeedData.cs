using EduCoach.API.Models;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Data;

public static class SeedData
{
    public static async Task InitializeAsync(AppDbContext dbContext)
    {
        if (!await dbContext.Topics.AnyAsync())
        {
            dbContext.Topics.AddRange(
                new Topic { Id = 1, Name = "Fracciones", Description = "Operaciones basicas con fracciones", IconName = "pie_chart" },
                new Topic { Id = 2, Name = "Algebra Basica", Description = "Expresiones y ecuaciones de primer grado", IconName = "functions" });
        }

        if (!await dbContext.Questions.AnyAsync())
        {
            dbContext.Questions.AddRange(BuildDiagnosticQuestions());
            dbContext.Questions.AddRange(BuildPracticeQuestions());
        }

        await dbContext.SaveChangesAsync();
    }

    private static IEnumerable<Question> BuildDiagnosticQuestions()
    {
        return
        [
            new Question { Id = Guid.Parse("11111111-1111-1111-1111-111111111001"), TopicId = 1, DifficultyLevel = 1, Statement = "Cuanto es 1/2 + 1/4?", OptionA = "3/4", OptionB = "2/6", OptionC = "1/4", OptionD = "1", CorrectOption = "A", Hint = "Busca un denominador comun.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("11111111-1111-1111-1111-111111111002"), TopicId = 1, DifficultyLevel = 1, Statement = "Cuanto es 3/4 - 1/4?", OptionA = "1/2", OptionB = "2/4", OptionC = "3/8", OptionD = "1/4", CorrectOption = "B", Hint = "Si el denominador es el mismo, resta numeradores.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("11111111-1111-1111-1111-111111111003"), TopicId = 1, DifficultyLevel = 1, Statement = "Cual fraccion es equivalente a 2/6?", OptionA = "1/3", OptionB = "2/3", OptionC = "3/2", OptionD = "4/6", CorrectOption = "A", Hint = "Simplifica dividiendo numerador y denominador.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("11111111-1111-1111-1111-111111111004"), TopicId = 1, DifficultyLevel = 2, Statement = "Cuanto es 2/3 x 3/4?", OptionA = "6/12", OptionB = "5/7", OptionC = "1/2", OptionD = "3/2", CorrectOption = "C", Hint = "Multiplica numeradores y denominadores.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("11111111-1111-1111-1111-111111111005"), TopicId = 1, DifficultyLevel = 2, Statement = "Cuanto es 4/5 dividido entre 2/5?", OptionA = "2", OptionB = "8/25", OptionC = "1", OptionD = "5/2", CorrectOption = "A", Hint = "Invierte la segunda fraccion y multiplica.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("22222222-2222-2222-2222-222222222001"), TopicId = 2, DifficultyLevel = 1, Statement = "Si x + 3 = 7, cuanto vale x?", OptionA = "3", OptionB = "4", OptionC = "5", OptionD = "10", CorrectOption = "B", Hint = "Despeja x restando 3 en ambos lados.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("22222222-2222-2222-2222-222222222002"), TopicId = 2, DifficultyLevel = 1, Statement = "Cuanto es 2x si x = 5?", OptionA = "7", OptionB = "10", OptionC = "25", OptionD = "3", CorrectOption = "B", Hint = "Reemplaza x por su valor.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("22222222-2222-2222-2222-222222222003"), TopicId = 2, DifficultyLevel = 1, Statement = "Simplifica 3x + 2x.", OptionA = "5x", OptionB = "6x", OptionC = "x", OptionD = "5", CorrectOption = "A", Hint = "Suma terminos semejantes.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("22222222-2222-2222-2222-222222222004"), TopicId = 2, DifficultyLevel = 2, Statement = "Si 2x = 12, cuanto vale x?", OptionA = "5", OptionB = "6", OptionC = "12", OptionD = "24", CorrectOption = "B", Hint = "Divide ambos lados entre 2.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("22222222-2222-2222-2222-222222222005"), TopicId = 2, DifficultyLevel = 2, Statement = "Cuanto es 4(x + 1) si x = 2?", OptionA = "8", OptionB = "10", OptionC = "12", OptionD = "6", CorrectOption = "C", Hint = "Primero resuelve el parentesis.", IsDiagnostic = true }
        ];
    }

    private static IEnumerable<Question> BuildPracticeQuestions()
    {
        return BuildFractionPracticeQuestions().Concat(BuildAlgebraPracticeQuestions());
    }

    private static IEnumerable<Question> BuildFractionPracticeQuestions()
    {
        return
        [
            CreatePracticeQuestion(1, 1, 1, "Cuanto es 1/3 + 1/3?", "2/3", "1/6", "1", "3/3", "A", "Suma fracciones con igual denominador."),
            CreatePracticeQuestion(1, 1, 2, "Cuanto es 3/5 - 1/5?", "1/5", "2/5", "3/10", "4/5", "B", "Resta solo los numeradores."),
            CreatePracticeQuestion(1, 1, 3, "Cual fraccion es equivalente a 2/4?", "1/4", "2/8", "1/2", "4/2", "C", "Simplifica la fraccion."),
            CreatePracticeQuestion(1, 1, 4, "Cuanto es 2/6 simplificado?", "1/3", "2/3", "3/2", "1/6", "A", "Divide numerador y denominador entre 2."),
            CreatePracticeQuestion(1, 1, 5, "Cuanto es 1/8 + 2/8?", "2/8", "3/8", "1/4", "4/8", "B", "Conserva el mismo denominador."),
            CreatePracticeQuestion(1, 1, 6, "Cuanto es 5/7 - 2/7?", "2/7", "3/7", "4/7", "5/14", "B", "Resta numeradores."),
            CreatePracticeQuestion(1, 1, 7, "Cual fraccion representa la mitad?", "2/6", "3/6", "4/6", "5/6", "B", "La mitad equivale a 1/2."),
            CreatePracticeQuestion(1, 1, 8, "Cuanto es 4/9 - 1/9?", "3/9", "4/9", "1/9", "5/9", "A", "Resta solo la parte superior."),
            CreatePracticeQuestion(1, 1, 9, "Cuanto es 2/10 + 3/10?", "3/10", "4/10", "5/10", "6/10", "C", "Suma los numeradores."),
            CreatePracticeQuestion(1, 1, 10, "Cual es equivalente a 3/6?", "1/4", "1/3", "2/3", "1/2", "D", "Simplifica dividiendo entre 3."),
            CreatePracticeQuestion(1, 2, 11, "Cuanto es 2/4 + 1/4?", "3/4", "3/8", "1/2", "1/4", "A", "Conserva el denominador comun."),
            CreatePracticeQuestion(1, 2, 12, "Cuanto es 5/6 - 1/6?", "4/6", "5/12", "3/6", "1/6", "A", "Resta los numeradores y simplifica si es necesario."),
            CreatePracticeQuestion(1, 2, 13, "Cuanto es 3/4 x 2/3?", "6/7", "1/2", "5/12", "3/2", "B", "Multiplica y luego simplifica."),
            CreatePracticeQuestion(1, 2, 14, "Cuanto es 1/2 x 4/5?", "2/5", "4/10", "1/5", "4/5", "A", "Multiplica numeradores y denominadores."),
            CreatePracticeQuestion(1, 2, 15, "Cuanto es 3/8 + 1/8?", "1/2", "4/8", "5/8", "3/16", "B", "La suma da 4/8."),
            CreatePracticeQuestion(1, 2, 16, "Cuanto es 7/10 - 3/10?", "2/10", "3/10", "4/10", "5/10", "C", "Resta las partes de diez."),
            CreatePracticeQuestion(1, 2, 17, "Cuanto es 2/3 + 1/6?", "3/9", "5/6", "1/2", "4/6", "B", "Busca denominador comun 6."),
            CreatePracticeQuestion(1, 2, 18, "Cuanto es 3/5 dividido entre 1/5?", "3", "2", "15", "3/25", "A", "Divide usando fraccion inversa."),
            CreatePracticeQuestion(1, 2, 19, "Cuanto es 4/9 + 2/9?", "5/9", "6/18", "6/9", "2/3", "C", "La suma directa da 6/9."),
            CreatePracticeQuestion(1, 2, 20, "Cuanto es 5/12 - 1/12?", "4/12", "3/12", "1/3", "5/11", "A", "Resta numeradores con mismo denominador."),
            CreatePracticeQuestion(1, 3, 21, "Cuanto es 5/6 dividido entre 1/2?", "5/12", "3/5", "5/3", "6/5", "C", "Invierte la segunda fraccion."),
            CreatePracticeQuestion(1, 3, 22, "Cual es el resultado de 7/8 - 1/4?", "6/8", "5/8", "3/4", "1/2", "B", "Convierte 1/4 a octavos."),
            CreatePracticeQuestion(1, 3, 23, "Cuanto es 2/3 + 3/4?", "17/12", "5/7", "1 5/12", "11/12", "C", "Busca denominador comun 12."),
            CreatePracticeQuestion(1, 3, 24, "Cuanto es 4/5 x 15/8?", "3/2", "60/40", "19/13", "11/8", "A", "Simplifica antes de multiplicar."),
            CreatePracticeQuestion(1, 3, 25, "Cuanto es 9/10 - 2/5?", "5/10", "1/2", "7/5", "7/10", "A", "Convierte 2/5 a decimos."),
            CreatePracticeQuestion(1, 3, 26, "Cuanto es 7/9 dividido entre 14/27?", "2/3", "3/2", "21/126", "14/9", "B", "Multiplica por el inverso."),
            CreatePracticeQuestion(1, 3, 27, "Cuanto es 5/12 + 7/18?", "22/30", "29/36", "12/30", "35/36", "B", "Usa denominador comun 36."),
            CreatePracticeQuestion(1, 3, 28, "Cuanto es 11/12 - 5/18?", "1/2", "23/36", "16/30", "6/36", "B", "Convierte ambas a treinta y seisavos."),
            CreatePracticeQuestion(1, 3, 29, "Cuanto es 3/7 x 14/9?", "2/3", "42/63", "17/16", "6/7", "A", "Simplifica 14 con 7 y 3 con 9."),
            CreatePracticeQuestion(1, 3, 30, "Cuanto es 8/15 dividido entre 4/25?", "10/3", "32/375", "2/5", "5/6", "A", "Invierte 4/25 y multiplica."),
        ];
    }

    private static IEnumerable<Question> BuildAlgebraPracticeQuestions()
    {
        return
        [
            CreatePracticeQuestion(2, 1, 1, "Si x + 5 = 9, cuanto vale x?", "4", "5", "14", "3", "A", "Resta 5 en ambos lados."),
            CreatePracticeQuestion(2, 1, 2, "Cuanto es 3x si x = 2?", "5", "6", "9", "1", "B", "Reemplaza x por 2."),
            CreatePracticeQuestion(2, 1, 3, "Simplifica 2x + 3x.", "5x", "6x", "x", "5", "A", "Suma terminos semejantes."),
            CreatePracticeQuestion(2, 1, 4, "Si x = 4, cuanto es x + 2?", "6", "8", "2", "4", "A", "Sustituye el valor de x."),
            CreatePracticeQuestion(2, 1, 5, "Resuelve x - 3 = 2.", "5", "1", "-1", "6", "A", "Suma 3 a ambos lados."),
            CreatePracticeQuestion(2, 1, 6, "Cuanto es 4x si x = 3?", "7", "12", "9", "1", "B", "Multiplica 4 por 3."),
            CreatePracticeQuestion(2, 1, 7, "Simplifica y + y + y.", "y", "2y", "3y", "y3", "C", "Cuenta cuantas veces aparece y."),
            CreatePracticeQuestion(2, 1, 8, "Si a = 5, cuanto es 2a + 1?", "11", "7", "10", "6", "A", "Primero multiplica 2 por 5."),
            CreatePracticeQuestion(2, 1, 9, "Resuelve x + 1 = 6.", "7", "6", "5", "4", "C", "Resta 1 a ambos lados."),
            CreatePracticeQuestion(2, 1, 10, "Cuanto es 10 - x si x = 4?", "14", "6", "4", "10", "B", "Sustituye y resta."),
            CreatePracticeQuestion(2, 2, 11, "Resuelve: 3x = 15", "3", "5", "15", "45", "B", "Divide ambos lados entre 3."),
            CreatePracticeQuestion(2, 2, 12, "Simplifica 4x + x", "4x", "x", "5x", "5", "C", "Son terminos semejantes."),
            CreatePracticeQuestion(2, 2, 13, "Resuelve x/2 = 6.", "3", "8", "12", "6", "C", "Multiplica ambos lados por 2."),
            CreatePracticeQuestion(2, 2, 14, "Si 2x + 1 = 9, cuanto vale x?", "3", "4", "5", "8", "B", "Resta 1 y divide entre 2."),
            CreatePracticeQuestion(2, 2, 15, "Simplifica 7a - 2a.", "9a", "5", "5a", "14a", "C", "Resta coeficientes."),
            CreatePracticeQuestion(2, 2, 16, "Cuanto es 3(x + 2) si x = 1?", "6", "9", "3", "5", "B", "Resuelve el parentesis y multiplica."),
            CreatePracticeQuestion(2, 2, 17, "Resuelve 5x = 20.", "2", "4", "5", "20", "B", "Divide entre 5."),
            CreatePracticeQuestion(2, 2, 18, "Si y - 4 = 10, cuanto vale y?", "6", "14", "4", "40", "B", "Suma 4 a ambos lados."),
            CreatePracticeQuestion(2, 2, 19, "Simplifica 2m + 2 + 3m.", "5m + 2", "7m", "5m", "2m + 5m", "A", "Agrupa solo terminos semejantes."),
            CreatePracticeQuestion(2, 2, 20, "Cuanto es 4(x - 1) si x = 3?", "4", "8", "12", "16", "B", "Primero resuelve el parentesis."),
            CreatePracticeQuestion(2, 3, 21, "Si 2x + 4 = 10, cuanto vale x?", "2", "3", "4", "5", "B", "Primero resta 4 y luego divide entre 2."),
            CreatePracticeQuestion(2, 3, 22, "Cuanto es 2(x + 3) si x = 4?", "14", "8", "11", "7", "A", "Resuelve el parentesis antes de multiplicar."),
            CreatePracticeQuestion(2, 3, 23, "Resuelve 3x - 5 = 16.", "11/3", "7", "21", "16/3", "B", "Suma 5 y divide entre 3."),
            CreatePracticeQuestion(2, 3, 24, "Simplifica 2(3x + 1).", "6x + 1", "5x + 2", "6x + 2", "3x + 2", "C", "Distribuye el 2."),
            CreatePracticeQuestion(2, 3, 25, "Resuelve (x/3) + 2 = 6.", "8", "12", "6", "4", "B", "Resta 2 y multiplica por 3."),
            CreatePracticeQuestion(2, 3, 26, "Si 4x - 8 = 12, cuanto vale x?", "4", "5", "6", "3", "B", "Suma 8 y divide entre 4."),
            CreatePracticeQuestion(2, 3, 27, "Simplifica 5(x - 2) + 3.", "5x - 7", "5x - 10", "8x - 2", "5x + 1", "A", "Distribuye y combina constantes."),
            CreatePracticeQuestion(2, 3, 28, "Resuelve 2(x + 1) = 14.", "5", "6", "7", "8", "B", "Divide entre 2 y luego resta 1."),
            CreatePracticeQuestion(2, 3, 29, "Cuanto es 3(2a - 1)?", "6a - 3", "6a - 1", "5a - 3", "6a + 3", "A", "Distribuye el 3."),
            CreatePracticeQuestion(2, 3, 30, "Resuelve 7 + 2x = 19.", "5", "6", "7", "12", "B", "Resta 7 y divide entre 2."),
        ];
    }

    private static Question CreatePracticeQuestion(
        int topicId,
        int difficultyLevel,
        int order,
        string statement,
        string optionA,
        string optionB,
        string optionC,
        string optionD,
        string correctOption,
        string hint)
    {
        return new Question
        {
            Id = Guid.Parse($"55555555-5555-5555-{topicId:D4}-{difficultyLevel:D2}{order:D10}"),
            TopicId = topicId,
            DifficultyLevel = difficultyLevel,
            Statement = statement,
            OptionA = optionA,
            OptionB = optionB,
            OptionC = optionC,
            OptionD = optionD,
            CorrectOption = correctOption,
            Hint = hint,
            IsDiagnostic = false
        };
    }
}
