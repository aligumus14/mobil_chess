using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ChessApp.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddMatchQueueTimeControl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "TimeControl",
                table: "MatchQueues",
                type: "int",
                nullable: false,
                defaultValue: 2); // OnlineTimeControl.Blitz5
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TimeControl",
                table: "MatchQueues");
        }
    }
}
