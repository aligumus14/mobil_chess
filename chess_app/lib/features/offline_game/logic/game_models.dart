enum BotDifficulty {
  easy,
  medium,
  hard;

  String get label => switch (this) {
    BotDifficulty.easy => 'Kolay',
    BotDifficulty.medium => 'Orta',
    BotDifficulty.hard => 'Zor',
  };

  String get description => switch (this) {
    BotDifficulty.easy => 'Kisa dusunme suresi ile oynar',
    BotDifficulty.medium => 'Dengeli Stockfish seviyesi',
    BotDifficulty.hard => 'Daha uzun dusunup daha guclu oynar',
  };
}

enum GameTimeControl {
  unlimited,
  blitz5,
  rapid10;

  String get label => switch (this) {
    GameTimeControl.unlimited => 'Limitsiz',
    GameTimeControl.blitz5 => 'Blitz 5+0',
    GameTimeControl.rapid10 => 'Rapid 10+0',
  };

  String get description => switch (this) {
    GameTimeControl.unlimited => 'Suresiz serbest oyun',
    GameTimeControl.blitz5 => 'Her taraf icin 5 dakika',
    GameTimeControl.rapid10 => 'Her taraf icin 10 dakika',
  };

  Duration? get initialDuration => switch (this) {
    GameTimeControl.unlimited => null,
    GameTimeControl.blitz5 => const Duration(minutes: 5),
    GameTimeControl.rapid10 => const Duration(minutes: 10),
  };

  String get pgnValue => switch (this) {
    GameTimeControl.unlimited => '-',
    GameTimeControl.blitz5 => '300+0',
    GameTimeControl.rapid10 => '600+0',
  };
}

enum PlayerColor { white, black, random }

class GameSettings {
  final PlayerColor playerColor;
  final BotDifficulty difficulty;
  final GameTimeControl timeControl;

  const GameSettings({
    this.playerColor = PlayerColor.white,
    this.difficulty = BotDifficulty.medium,
    this.timeControl = GameTimeControl.unlimited,
  });
}

class OfflineRecordedMove {
  final int moveNumber;
  final String fromSquare;
  final String toSquare;
  final String san;
  final String fenAfterMove;

  const OfflineRecordedMove({
    required this.moveNumber,
    required this.fromSquare,
    required this.toSquare,
    required this.san,
    required this.fenAfterMove,
  });
}

enum GameOutcome { whiteWin, blackWin, draw, ongoing }

class GameResult {
  final GameOutcome outcome;
  final String reason;
  final bool playerWon;

  const GameResult({
    required this.outcome,
    required this.reason,
    required this.playerWon,
  });
}
