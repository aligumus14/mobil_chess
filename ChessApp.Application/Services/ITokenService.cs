using ChessApp.Core.Entities;

namespace ChessApp.Application.Services;

public interface ITokenService
{
    string GenerateToken(User user);
}
