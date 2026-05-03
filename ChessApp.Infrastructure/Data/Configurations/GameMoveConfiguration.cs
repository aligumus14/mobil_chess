using ChessApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ChessApp.Infrastructure.Data.Configurations;

public class GameMoveConfiguration : IEntityTypeConfiguration<GameMove>
{
    public void Configure(EntityTypeBuilder<GameMove> builder)
    {
        builder.HasKey(m => m.Id);

        builder.Property(m => m.FromSquare).HasMaxLength(5);
        builder.Property(m => m.ToSquare).HasMaxLength(5);
        builder.Property(m => m.San).HasMaxLength(10);
        builder.Property(m => m.FenAfterMove).HasMaxLength(100);

        builder.HasIndex(m => m.GameId);

        builder.HasOne(m => m.Game)
            .WithMany(g => g.Moves)
            .HasForeignKey(m => m.GameId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(m => m.Player)
            .WithMany(u => u.Moves)
            .HasForeignKey(m => m.PlayerId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
