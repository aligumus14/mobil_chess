using ChessApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ChessApp.Infrastructure.Data.Configurations;

public class GameConfiguration : IEntityTypeConfiguration<Game>
{
    public void Configure(EntityTypeBuilder<Game> builder)
    {
        builder.HasKey(g => g.Id);

        builder.Property(g => g.Pgn).HasColumnType("nvarchar(max)");

        builder.Property(g => g.StartFen).HasMaxLength(100);
        builder.Property(g => g.CurrentFen).HasMaxLength(100);

        builder.HasOne(g => g.WhitePlayer)
            .WithMany(u => u.WhiteGames)
            .HasForeignKey(g => g.WhitePlayerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(g => g.BlackPlayer)
            .WithMany(u => u.BlackGames)
            .HasForeignKey(g => g.BlackPlayerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(g => g.Winner)
            .WithMany()
            .HasForeignKey(g => g.WinnerUserId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
