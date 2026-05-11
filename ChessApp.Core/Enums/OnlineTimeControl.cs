namespace ChessApp.Core.Enums;

public enum OnlineTimeControl
{
    Blitz3 = 0,         // 3+0
    Blitz3Plus2 = 1,    // 3+2
    Blitz5 = 2,         // 5+0
    Blitz5Plus2 = 3,    // 5+2
    Rapid10 = 4,        // 10+0
    Rapid10Plus2 = 5,   // 10+2
    Rapid15 = 6,        // 15+0
    Rapid15Plus3 = 7,   // 15+3
    Classical30 = 8,    // 30+0
}

public static class OnlineTimeControlExtensions
{
    public static (int InitialSeconds, int IncrementSeconds) ToSpec(this OnlineTimeControl tc)
        => tc switch
        {
            OnlineTimeControl.Blitz3 => (180, 0),
            OnlineTimeControl.Blitz3Plus2 => (180, 2),
            OnlineTimeControl.Blitz5 => (300, 0),
            OnlineTimeControl.Blitz5Plus2 => (300, 2),
            OnlineTimeControl.Rapid10 => (600, 0),
            OnlineTimeControl.Rapid10Plus2 => (600, 2),
            OnlineTimeControl.Rapid15 => (900, 0),
            OnlineTimeControl.Rapid15Plus3 => (900, 3),
            OnlineTimeControl.Classical30 => (1800, 0),
            _ => (300, 0),
        };

    public static string ToPgnTag(this OnlineTimeControl tc)
    {
        var (init, inc) = tc.ToSpec();
        return $"{init}+{inc}";
    }
}
