using ChessApp.Application.DTOs;
using ChessApp.Core.Interfaces;

namespace ChessApp.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;

    public UserService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<UserProfileDto?> GetProfileAsync(Guid userId)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null) return null;

        return new UserProfileDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            Elo = user.Elo,
            Wins = user.Wins,
            Losses = user.Losses,
            Draws = user.Draws,
            CreatedAt = user.CreatedAt
        };
    }

    public async Task<UserProfileDto?> UpdateProfileAsync(Guid userId, UpdateProfileDto dto)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null) return null;

        if (!string.IsNullOrEmpty(dto.Username))
        {
            var existing = await _unitOfWork.Users.FirstOrDefaultAsync(
                u => u.Username == dto.Username && u.Id != userId);
            if (existing != null)
                throw new InvalidOperationException("Bu kullanıcı adı zaten kullanımda.");
            user.Username = dto.Username;
        }

        if (!string.IsNullOrEmpty(dto.Email))
        {
            var existing = await _unitOfWork.Users.FirstOrDefaultAsync(
                u => u.Email == dto.Email && u.Id != userId);
            if (existing != null)
                throw new InvalidOperationException("Bu e-posta zaten kullanımda.");
            user.Email = dto.Email;
        }

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync();

        return new UserProfileDto
        {
            Id = user.Id,
            Username = user.Username,
            Email = user.Email,
            Elo = user.Elo,
            Wins = user.Wins,
            Losses = user.Losses,
            Draws = user.Draws,
            CreatedAt = user.CreatedAt
        };
    }
}
