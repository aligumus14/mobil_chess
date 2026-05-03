using ChessApp.Core.Entities;

namespace ChessApp.Core.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IGenericRepository<User> Users { get; }
    IGenericRepository<Game> Games { get; }
    IGenericRepository<GameMove> GameMoves { get; }
    IGenericRepository<EloHistory> EloHistories { get; }
    IGenericRepository<MatchQueue> MatchQueues { get; }
    IGenericRepository<AnalysisResult> AnalysisResults { get; }
    Task<int> SaveChangesAsync();
}
