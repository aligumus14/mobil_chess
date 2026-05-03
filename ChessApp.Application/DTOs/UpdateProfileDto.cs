using System.ComponentModel.DataAnnotations;

namespace ChessApp.Application.DTOs;

public class UpdateProfileDto
{
    [StringLength(50, MinimumLength = 3)]
    public string? Username { get; set; }

    [EmailAddress]
    public string? Email { get; set; }
}
