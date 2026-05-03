using ChessApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ChessApp.Infrastructure.Data.Configurations;

public class MatchQueueConfiguration : IEntityTypeConfiguration<MatchQueue>
{
    public void Configure(EntityTypeBuilder<MatchQueue> builder)
    {
        builder.HasKey(m => m.Id);

        builder.HasOne(m => m.User)
            .WithMany()
            .HasForeignKey(m => m.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
