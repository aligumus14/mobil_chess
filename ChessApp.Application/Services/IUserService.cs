using ChessApp.Application.DTOs;

namespace ChessApp.Application.Services;

public interface IUserService
{
    Task<UserProfileDto?> GetProfileAsync(Guid userId);
    Task<UserProfileDto?> UpdateProfileAsync(Guid userId, UpdateProfileDto dto);
}
