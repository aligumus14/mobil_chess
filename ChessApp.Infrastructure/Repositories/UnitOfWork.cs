using ChessApp.Core.Entities;
using ChessApp.Core.Interfaces;
using ChessApp.Infrastructure.Data;

namespace ChessApp.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly ChessDbContext _context;

    public IGenericRepository<User> Users { get; }
    public IGenericRepository<Game> Games { get; }
    public IGenericRepository<GameMove> GameMoves { get; }
    public IGenericRepository<EloHistory> EloHistories { get; }
    public IGenericRepository<MatchQueue> MatchQueues { get; }
    public IGenericRepository<AnalysisResult> AnalysisResults { get; }

    public UnitOfWork(ChessDbContext context)
    {
        _context = context;
        Users = new GenericRepository<User>(context);
        Games = new GenericRepository<Game>(context);
        GameMoves = new GenericRepository<GameMove>(context);
        EloHistories = new GenericRepository<EloHistory>(context);
        MatchQueues = new GenericRepository<MatchQueue>(context);
        AnalysisResults = new GenericRepository<AnalysisResult>(context);
    }

    public async Task<int> SaveChangesAsync()
        => await _context.SaveChangesAsync();

    public void Dispose()
        => _context.Dispose();
}
