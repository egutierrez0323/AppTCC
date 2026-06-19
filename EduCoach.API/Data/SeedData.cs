using EduCoach.API.Models;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Data;

public static class SeedData
{
    public static async Task InitializeAsync(AppDbContext dbContext)
    {
        var existingTopicIds = await dbContext.Topics
            .AsNoTracking()
            .Select(topic => topic.Id)
            .ToListAsync();
        var missingTopics = BuildTopics()
            .Where(topic => !existingTopicIds.Contains(topic.Id))
            .ToList();
        if (missingTopics.Count > 0)
        {
            dbContext.Topics.AddRange(missingTopics);
        }

        var existingQuestionIds = await dbContext.Questions
            .AsNoTracking()
            .Select(question => question.Id)
            .ToListAsync();
        var missingQuestions = BuildDiagnosticQuestions()
            .Concat(BuildPracticeQuestions())
            .Where(question => !existingQuestionIds.Contains(question.Id))
            .ToList();
        if (missingQuestions.Count > 0)
        {
            dbContext.Questions.AddRange(missingQuestions);
        }

        await dbContext.SaveChangesAsync();
    }

    private static IEnumerable<Topic> BuildTopics()
    {
        return
        [
            new Topic { Id = 1, Name = "Fracciones", Description = "Operaciones basicas con fracciones", IconName = "pie_chart" },
            new Topic { Id = 2, Name = "Algebra Basica", Description = "Expresiones y ecuaciones de primer grado", IconName = "functions" },
            new Topic { Id = 3, Name = "Decimales", Description = "Operaciones y comparacion con numeros decimales", IconName = "calculate" },
            new Topic { Id = 4, Name = "Geometria Basica", Description = "Perimetro, area y figuras geometricas simples", IconName = "category" },
            new Topic { Id = 99, Name = "Practica mixta", Description = "Sesion con preguntas mezcladas de varios temas", IconName = "shuffle" }
        ];
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
            new Question { Id = Guid.Parse("22222222-2222-2222-2222-222222222005"), TopicId = 2, DifficultyLevel = 2, Statement = "Cuanto es 4(x + 1) si x = 2?", OptionA = "8", OptionB = "10", OptionC = "12", OptionD = "6", CorrectOption = "C", Hint = "Primero resuelve el parentesis.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("33333333-3333-3333-3333-333333333001"), TopicId = 3, DifficultyLevel = 1, Statement = "Cuanto es 0.5 + 0.2?", OptionA = "0.7", OptionB = "0.3", OptionC = "0.52", OptionD = "7.0", CorrectOption = "A", Hint = "Alinea la coma decimal y suma normalmente.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("33333333-3333-3333-3333-333333333002"), TopicId = 3, DifficultyLevel = 1, Statement = "Cual numero es mayor?", OptionA = "1.25", OptionB = "1.3", OptionC = "1.03", OptionD = "1.205", CorrectOption = "B", Hint = "Compara cifra por cifra despues de la coma.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("33333333-3333-3333-3333-333333333003"), TopicId = 3, DifficultyLevel = 1, Statement = "Cuanto es 2.4 - 1.1?", OptionA = "1.2", OptionB = "1.5", OptionC = "1.3", OptionD = "0.13", CorrectOption = "C", Hint = "Resta las decimas y las unidades por separado.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("33333333-3333-3333-3333-333333333004"), TopicId = 3, DifficultyLevel = 2, Statement = "Cuanto es 0.6 x 10?", OptionA = "0.06", OptionB = "6", OptionC = "60", OptionD = "0.6", CorrectOption = "B", Hint = "Multiplicar por 10 mueve la coma un lugar a la derecha.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("33333333-3333-3333-3333-333333333005"), TopicId = 3, DifficultyLevel = 2, Statement = "Cuanto es 3.5 dividido entre 0.5?", OptionA = "1.75", OptionB = "7", OptionC = "3", OptionD = "0.7", CorrectOption = "B", Hint = "Dividir entre 0.5 equivale a preguntar cuantas mitades caben.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("44444444-4444-4444-4444-444444444001"), TopicId = 4, DifficultyLevel = 1, Statement = "Cuantos lados tiene un triangulo?", OptionA = "2", OptionB = "3", OptionC = "4", OptionD = "5", CorrectOption = "B", Hint = "Piensa en la figura mas basica de tres lados.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("44444444-4444-4444-4444-444444444002"), TopicId = 4, DifficultyLevel = 1, Statement = "Cual es el perimetro de un cuadrado de lado 4?", OptionA = "8", OptionB = "12", OptionC = "16", OptionD = "20", CorrectOption = "C", Hint = "El perimetro del cuadrado es 4 veces el lado.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("44444444-4444-4444-4444-444444444003"), TopicId = 4, DifficultyLevel = 1, Statement = "Cual es el area de un rectangulo de 5 por 3?", OptionA = "8", OptionB = "15", OptionC = "16", OptionD = "30", CorrectOption = "B", Hint = "El area del rectangulo es base por altura.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("44444444-4444-4444-4444-444444444004"), TopicId = 4, DifficultyLevel = 2, Statement = "Cuantos grados tiene un angulo recto?", OptionA = "45", OptionB = "90", OptionC = "120", OptionD = "180", CorrectOption = "B", Hint = "Es la mitad de un angulo llano.", IsDiagnostic = true },
            new Question { Id = Guid.Parse("44444444-4444-4444-4444-444444444005"), TopicId = 4, DifficultyLevel = 2, Statement = "Cuanto suman los angulos internos de un triangulo?", OptionA = "90", OptionB = "180", OptionC = "270", OptionD = "360", CorrectOption = "B", Hint = "Es una propiedad basica de todos los triangulos.", IsDiagnostic = true }
        ];
    }

    private static IEnumerable<Question> BuildPracticeQuestions()
    {
        return BuildFractionPracticeQuestions()
            .Concat(BuildAlgebraPracticeQuestions())
            .Concat(BuildDecimalPracticeQuestions())
            .Concat(BuildGeometryPracticeQuestions());
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
            CreatePracticeQuestion(1, 1, 31, "Cuanto es 6/8 simplificado?", "2/3", "3/4", "4/6", "1/8", "B", "Divide numerador y denominador entre 2."),
            CreatePracticeQuestion(1, 2, 32, "Cuanto es 5/6 + 1/3?", "6/9", "1", "7/6", "5/18", "C", "Convierte 1/3 a sextos antes de sumar."),
            CreatePracticeQuestion(1, 2, 33, "Cuanto es 7/12 - 1/3?", "1/4", "1/3", "6/12", "2/9", "A", "Convierte 1/3 a doceavos y luego resta."),
            CreatePracticeQuestion(1, 3, 34, "Cuanto es 9/14 + 2/7?", "11/21", "13/14", "1", "5/7", "B", "Convierte 2/7 a catorceavos antes de sumar."),
            CreatePracticeQuestion(1, 3, 35, "Cuanto es 3/4 dividido entre 9/8?", "2/3", "3/2", "27/32", "8/9", "A", "Divide multiplicando por el inverso de 9/8."),
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
            CreatePracticeQuestion(2, 1, 31, "Si x + 8 = 13, cuanto vale x?", "4", "5", "6", "21", "B", "Resta 8 a ambos lados."),
            CreatePracticeQuestion(2, 2, 32, "Simplifica 6y - y + 2.", "5y + 2", "7y + 2", "5y", "6y + 1", "A", "Combina primero los terminos semejantes."),
            CreatePracticeQuestion(2, 2, 33, "Si 3x + 2 = 11, cuanto vale x?", "3", "9", "11", "13", "A", "Resta 2 y luego divide entre 3."),
            CreatePracticeQuestion(2, 3, 34, "Resuelve 4(x - 2) = 20.", "5", "6", "7", "8", "C", "Divide entre 4 y luego suma 2."),
            CreatePracticeQuestion(2, 3, 35, "Simplifica 2(2m + 3) - m.", "3m + 6", "4m + 3", "m + 6", "4m - 3", "A", "Distribuye el 2 y luego combina terminos."),
        ];
    }

    private static IEnumerable<Question> BuildDecimalPracticeQuestions()
    {
        return
        [
            CreatePracticeQuestion(3, 1, 1, "Cuanto es 0.2 + 0.3?", "0.5", "0.23", "0.6", "0.03", "A", "Suma las decimas alineando la coma."),
            CreatePracticeQuestion(3, 1, 2, "Cuanto es 1.5 - 0.4?", "1.9", "1.1", "1.4", "0.11", "B", "Resta decima con decima."),
            CreatePracticeQuestion(3, 1, 3, "Cual numero es mayor?", "0.08", "0.8", "0.18", "0.28", "B", "Un numero con ocho decimas es mayor que ocho centesimas."),
            CreatePracticeQuestion(3, 1, 4, "Cuanto es 0.7 x 10?", "7", "0.07", "70", "0.7", "A", "Multiplicar por 10 mueve la coma un lugar a la derecha."),
            CreatePracticeQuestion(3, 1, 5, "Cuanto es 3.2 dividido entre 10?", "32", "3.02", "0.32", "0.032", "C", "Dividir entre 10 mueve la coma un lugar a la izquierda."),
            CreatePracticeQuestion(3, 2, 6, "Cuanto es 2.35 + 1.4?", "3.65", "3.75", "2.49", "3.15", "B", "Escribe 1.4 como 1.40 para alinear la suma."),
            CreatePracticeQuestion(3, 2, 7, "Cuanto es 5.6 - 2.75?", "2.85", "3.15", "2.95", "3.85", "A", "Convierte 5.6 en 5.60 para restar con facilidad."),
            CreatePracticeQuestion(3, 2, 8, "Cuanto es 0.25 x 4?", "0.5", "1", "1.25", "0.75", "B", "Cuatro veces un cuarto es una unidad."),
            CreatePracticeQuestion(3, 2, 9, "Cuanto es 1.2 + 0.08?", "1.28", "1.10", "1.8", "1.208", "A", "Suma decimas y centesimas por separado."),
            CreatePracticeQuestion(3, 2, 10, "Que fraccion equivale a 0.5?", "1/5", "5/100", "5/10", "1/20", "C", "Cinco decimas representan la mitad."),
            CreatePracticeQuestion(3, 3, 11, "Cuanto es 3.75 dividido entre 1.5?", "2", "2.5", "25", "1.25", "B", "Piensa cuantas veces cabe 1.5 dentro de 3.75."),
            CreatePracticeQuestion(3, 3, 12, "Cuanto es 0.04 x 100?", "0.4", "4", "40", "0.004", "B", "Multiplicar por 100 mueve la coma dos lugares."),
            CreatePracticeQuestion(3, 3, 13, "Cuanto es 2.5 - 0.875?", "1.625", "1.725", "2.375", "1.575", "A", "Escribe 2.5 como 2.500 antes de restar."),
            CreatePracticeQuestion(3, 3, 14, "Cuanto es 1.25 + 2.375?", "3.5", "3.625", "3.575", "2.500", "B", "Alinea unidades, decimas, centesimas y milesimas."),
            CreatePracticeQuestion(3, 3, 15, "Cuanto es 4.8 dividido entre 0.6?", "0.8", "8", "48", "6", "B", "Puedes pensar en 48 dividido entre 6."),
        ];
    }

    private static IEnumerable<Question> BuildGeometryPracticeQuestions()
    {
        return
        [
            CreatePracticeQuestion(4, 1, 1, "Cuantos lados tiene un cuadrilatero?", "3", "4", "5", "6", "B", "La palabra quadri indica cuatro."),
            CreatePracticeQuestion(4, 1, 2, "Cual es el area de un cuadrado de lado 3?", "6", "9", "12", "27", "B", "El area del cuadrado es lado por lado."),
            CreatePracticeQuestion(4, 1, 3, "Cual es el perimetro de un triangulo equilatero de lado 5?", "10", "15", "20", "25", "B", "Suma sus tres lados iguales."),
            CreatePracticeQuestion(4, 1, 4, "Cuantos grados mide un angulo recto?", "45", "60", "90", "180", "C", "Es la mitad de un angulo llano."),
            CreatePracticeQuestion(4, 1, 5, "Que figura tiene 4 lados iguales y 4 angulos rectos?", "Rombo", "Rectangulo", "Triangulo", "Cuadrado", "D", "Busca la figura que cumple ambas condiciones."),
            CreatePracticeQuestion(4, 2, 6, "Cual es el perimetro de un rectangulo de lados 6 y 2?", "8", "12", "16", "24", "C", "Suma dos veces el largo y dos veces el ancho."),
            CreatePracticeQuestion(4, 2, 7, "Cual es el area de un rectangulo de base 7 y altura 4?", "11", "21", "28", "35", "C", "Multiplica base por altura."),
            CreatePracticeQuestion(4, 2, 8, "Cuanto suman los angulos internos de un triangulo?", "90", "180", "270", "360", "B", "Es una propiedad fija de esa figura."),
            CreatePracticeQuestion(4, 2, 9, "Si el perimetro de un cuadrado es 20, cuanto mide cada lado?", "4", "5", "6", "10", "B", "Divide el perimetro total entre 4."),
            CreatePracticeQuestion(4, 2, 10, "Cuantos vertices tiene un triangulo?", "2", "3", "4", "6", "B", "Cada punta de la figura es un vertice."),
            CreatePracticeQuestion(4, 3, 11, "Cual es el area de un triangulo de base 10 y altura 4?", "20", "40", "14", "24", "A", "Usa base por altura y luego divide entre 2."),
            CreatePracticeQuestion(4, 3, 12, "Si el area de un cuadrado es 16, cual es su perimetro?", "8", "12", "16", "20", "C", "Primero encuentra el lado y luego calcula el perimetro."),
            CreatePracticeQuestion(4, 3, 13, "Si dos angulos de un triangulo miden 50 y 60 grados, cuanto mide el tercero?", "60", "70", "80", "110", "B", "Resta a 180 la suma de los otros dos angulos."),
            CreatePracticeQuestion(4, 3, 14, "Cual es el perimetro de un rectangulo de base 8 y altura 3?", "11", "22", "24", "48", "B", "Suma base + altura + base + altura."),
            CreatePracticeQuestion(4, 3, 15, "Si el area de un rectangulo es 24 y su base es 4, cuanto mide la altura?", "5", "6", "8", "12", "B", "Divide el area entre la base."),
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
