using ChessApp.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace ChessApp.Infrastructure.Data;

public class ChessDbContext : DbContext
{
    public ChessDbContext(DbContextOptions<ChessDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Game> Games => Set<Game>();
    public DbSet<GameMove> GameMoves => Set<GameMove>();
    public DbSet<EloHistory> EloHistories => Set<EloHistory>();
    public DbSet<MatchQueue> MatchQueues => Set<MatchQueue>();
    public DbSet<AnalysisResult> AnalysisResults => Set<AnalysisResult>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ChessDbContext).Assembly);
    }
}
