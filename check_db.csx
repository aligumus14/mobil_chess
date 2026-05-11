#r "nuget: Microsoft.Data.SqlClient, 5.2.0"
using Microsoft.Data.SqlClient;

var cs = @"Server=(localdb)\mssqllocaldb;Database=ChessAppDb;Trusted_Connection=true;MultipleActiveResultSets=true";
using var conn = new SqlConnection(cs);
conn.Open();

Console.WriteLine("=== MatchQueues columns ===");
using (var cmd = new SqlCommand("SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='MatchQueues' ORDER BY ORDINAL_POSITION", conn))
using (var r = cmd.ExecuteReader())
{
    while (r.Read())
        Console.WriteLine($"  {r["COLUMN_NAME"]} : {r["DATA_TYPE"]}");
}

Console.WriteLine();
Console.WriteLine("=== Current MatchQueues rows ===");
using (var cmd = new SqlCommand("SELECT Id, UserId, EloSnapshot, QueuedAt, Status, TimeControl FROM MatchQueues", conn))
using (var r = cmd.ExecuteReader())
{
    int n = 0;
    while (r.Read())
    {
        n++;
        Console.WriteLine($"  Id={r["Id"]} UserId={r["UserId"]} Elo={r["EloSnapshot"]} Queued={r["QueuedAt"]} Status={r["Status"]} TC={r["TimeControl"]}");
    }
    Console.WriteLine($"  ({n} row(s))");
}

Console.WriteLine();
Console.WriteLine("=== Applied migrations ===");
using (var cmd = new SqlCommand("SELECT MigrationId FROM __EFMigrationsHistory ORDER BY MigrationId", conn))
using (var r = cmd.ExecuteReader())
{
    while (r.Read())
        Console.WriteLine($"  {r["MigrationId"]}");
}
