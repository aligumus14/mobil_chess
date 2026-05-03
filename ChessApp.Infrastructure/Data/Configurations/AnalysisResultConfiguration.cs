using ChessApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ChessApp.Infrastructure.Data.Configurations;

public class AnalysisResultConfiguration : IEntityTypeConfiguration<AnalysisResult>
{
    public void Configure(EntityTypeBuilder<AnalysisResult> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.BestMove).HasMaxLength(10);
        builder.Property(a => a.PlayedMove).HasMaxLength(10);

        builder.HasOne(a => a.Game)
            .WithMany(g => g.AnalysisResults)
            .HasForeignKey(a => a.GameId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
