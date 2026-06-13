using EduCoach.API.Models;
using Microsoft.EntityFrameworkCore;

namespace EduCoach.API.Data;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Topic> Topics => Set<Topic>();
    public DbSet<Question> Questions => Set<Question>();
    public DbSet<DiagnosticResult> DiagnosticResults => Set<DiagnosticResult>();
    public DbSet<PracticeSession> PracticeSessions => Set<PracticeSession>();
    public DbSet<UserResponse> UserResponses => Set<UserResponse>();
    public DbSet<UserProgress> UserProgress => Set<UserProgress>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>()
            .HasIndex(user => user.Email)
            .IsUnique();

        modelBuilder.Entity<UserProgress>()
            .HasIndex(progress => new { progress.UserId, progress.TopicId })
            .IsUnique();

        modelBuilder.Entity<Question>()
            .Property(question => question.CorrectOption)
            .HasMaxLength(1);

        modelBuilder.Entity<UserResponse>()
            .Property(response => response.SelectedOption)
            .HasMaxLength(1);

        modelBuilder.Entity<UserResponse>()
            .HasIndex(response => new { response.SessionId, response.QuestionId })
            .IsUnique();

        modelBuilder.Entity<DiagnosticResult>()
            .HasOne(result => result.User)
            .WithMany(user => user.DiagnosticResults)
            .HasForeignKey(result => result.UserId);

        modelBuilder.Entity<DiagnosticResult>()
            .HasOne(result => result.Topic)
            .WithMany(topic => topic.DiagnosticResults)
            .HasForeignKey(result => result.TopicId);

        modelBuilder.Entity<Question>()
            .HasOne(question => question.Topic)
            .WithMany(topic => topic.Questions)
            .HasForeignKey(question => question.TopicId);

        modelBuilder.Entity<PracticeSession>()
            .HasOne(session => session.User)
            .WithMany(user => user.PracticeSessions)
            .HasForeignKey(session => session.UserId);

        modelBuilder.Entity<PracticeSession>()
            .HasOne(session => session.Topic)
            .WithMany(topic => topic.PracticeSessions)
            .HasForeignKey(session => session.TopicId);

        modelBuilder.Entity<UserResponse>()
            .HasOne(response => response.Session)
            .WithMany(session => session.Responses)
            .HasForeignKey(response => response.SessionId);

        modelBuilder.Entity<UserResponse>()
            .HasOne(response => response.Question)
            .WithMany(question => question.UserResponses)
            .HasForeignKey(response => response.QuestionId);

        modelBuilder.Entity<UserProgress>()
            .HasOne(progress => progress.User)
            .WithMany(user => user.ProgressEntries)
            .HasForeignKey(progress => progress.UserId);

        modelBuilder.Entity<UserProgress>()
            .HasOne(progress => progress.Topic)
            .WithMany(topic => topic.ProgressEntries)
            .HasForeignKey(progress => progress.TopicId);
    }
}
