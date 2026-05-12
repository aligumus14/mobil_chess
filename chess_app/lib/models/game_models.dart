enum ApiGameType { online, offline, offlineBot }

ApiGameType _gameTypeFromJson(dynamic v) {
  if (v is int) return ApiGameType.values[v];
  if (v is String) {
    return ApiGameType.values.firstWhere(
      (e) => e.name.toLowerCase() == v.toLowerCase(),
      orElse: () => ApiGameType.offlineBot,
    );
  }
  return ApiGameType.offlineBot;
}

int _gameTypeToJson(ApiGameType t) => t.index;

enum ApiGameResult { whiteWin, blackWin, draw }

ApiGameResult? _resultFromJson(dynamic v) {
  if (v == null) return null;
  if (v is int) return ApiGameResult.values[v];
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'whitewin' || s == 'white_win') return ApiGameResult.whiteWin;
    if (s == 'blackwin' || s == 'black_win') return ApiGameResult.blackWin;
    if (s == 'draw') return ApiGameResult.draw;
  }
  return null;
}

int _resultToJson(ApiGameResult r) => r.index;

enum AnalysisClassification { best, good, inaccuracy, mistake, blunder }

AnalysisClassification _analysisClassificationFromJson(dynamic value) {
  if (value is int) {
    return AnalysisClassification.values[value];
  }

  if (value is String) {
    return AnalysisClassification.values.firstWhere(
      (item) => item.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AnalysisClassification.good,
    );
  }

  return AnalysisClassification.good;
}

class GameListItem {
  final String id;
  final ApiGameType gameType;
  final ApiGameResult? result;
  final String playerColor; // "white" | "black"
  final bool playerWon;
  final String? botDifficulty;
  final int moveCount;
  final DateTime startedAt;
  final DateTime? endedAt;

  GameListItem({
    required this.id,
    required this.gameType,
    required this.result,
    required this.playerColor,
    required this.playerWon,
    required this.botDifficulty,
    required this.moveCount,
    required this.startedAt,
    required this.endedAt,
  });

  factory GameListItem.fromJson(Map<String, dynamic> json) => GameListItem(
    id: json['id'] as String,
    gameType: _gameTypeFromJson(json['gameType']),
    result: _resultFromJson(json['result']),
    playerColor: (json['playerColor'] as String?) ?? 'white',
    playerWon: (json['playerWon'] as bool?) ?? false,
    botDifficulty: json['botDifficulty'] as String?,
    moveCount: (json['moveCount'] as int?) ?? 0,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'] as String),
  );
}

class GameMoveDetail {
  final int moveNumber;
  final String fromSquare;
  final String toSquare;
  final String san;
  final String fenAfterMove;
  final DateTime playedAt;

  GameMoveDetail({
    required this.moveNumber,
    required this.fromSquare,
    required this.toSquare,
    required this.san,
    required this.fenAfterMove,
    required this.playedAt,
  });

  factory GameMoveDetail.fromJson(Map<String, dynamic> json) => GameMoveDetail(
    moveNumber: json['moveNumber'] as int,
    fromSquare: json['fromSquare'] as String,
    toSquare: json['toSquare'] as String,
    san: json['san'] as String,
    fenAfterMove: json['fenAfterMove'] as String,
    playedAt: DateTime.parse(json['playedAt'] as String),
  );
}

class GameDetail {
  final String id;
  final ApiGameType gameType;
  final ApiGameResult? result;
  final String playerColor;
  final bool playerWon;
  final String? botDifficulty;
  final String startFen;
  final String currentFen;
  final String? pgn;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<GameMoveDetail> moves;

  GameDetail({
    required this.id,
    required this.gameType,
    required this.result,
    required this.playerColor,
    required this.playerWon,
    required this.botDifficulty,
    required this.startFen,
    required this.currentFen,
    required this.pgn,
    required this.startedAt,
    required this.endedAt,
    required this.moves,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) => GameDetail(
    id: json['id'] as String,
    gameType: _gameTypeFromJson(json['gameType']),
    result: _resultFromJson(json['result']),
    playerColor: (json['playerColor'] as String?) ?? 'white',
    playerWon: (json['playerWon'] as bool?) ?? false,
    botDifficulty: json['botDifficulty'] as String?,
    startFen: json['startFen'] as String,
    currentFen: json['currentFen'] as String,
    pgn: json['pgn'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'] as String),
    moves: ((json['moves'] as List?) ?? const [])
        .map((e) => GameMoveDetail.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PagedGames {
  final List<GameListItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  PagedGames({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PagedGames.fromJson(Map<String, dynamic> json) => PagedGames(
    items: ((json['items'] as List?) ?? const [])
        .map((e) => GameListItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: json['page'] as int,
    pageSize: json['pageSize'] as int,
    totalCount: json['totalCount'] as int,
    totalPages: json['totalPages'] as int,
  );
}

class CreateGameMovePayload {
  final int moveNumber;
  final String fromSquare;
  final String toSquare;
  final String san;
  final String fenAfterMove;

  CreateGameMovePayload({
    required this.moveNumber,
    required this.fromSquare,
    required this.toSquare,
    required this.san,
    required this.fenAfterMove,
  });

  Map<String, dynamic> toJson() => {
    'moveNumber': moveNumber,
    'fromSquare': fromSquare,
    'toSquare': toSquare,
    'san': san,
    'fenAfterMove': fenAfterMove,
  };
}

class CreateGamePayload {
  final ApiGameType gameType;
  final String playerColor;
  final String? botDifficulty;
  final String? timeControl;
  final String? terminationReason;
  final ApiGameResult result;
  final String startFen;
  final String finalFen;
  final String pgn;
  final List<CreateGameMovePayload> moves;
  final DateTime startedAt;
  final DateTime endedAt;

  CreateGamePayload({
    required this.gameType,
    required this.playerColor,
    required this.botDifficulty,
    required this.timeControl,
    required this.terminationReason,
    required this.result,
    required this.startFen,
    required this.finalFen,
    required this.pgn,
    required this.moves,
    required this.startedAt,
    required this.endedAt,
  });

  Map<String, dynamic> toJson() => {
    'gameType': _gameTypeToJson(gameType),
    'playerColor': playerColor,
    'botDifficulty': botDifficulty,
    'timeControl': timeControl,
    'terminationReason': terminationReason,
    'result': _resultToJson(result),
    'startFen': startFen,
    'finalFen': finalFen,
    'pgn': pgn,
    'moves': moves.map((m) => m.toJson()).toList(),
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt.toUtc().toIso8601String(),
  };
}

class MoveAnalysis {
  final int moveNumber;
  final String san;
  final String fenBeforeMove;
  final String fenAfterMove;
  final String bestMove;
  final String playedMove;
  final double evaluation;
  final double centipawnLoss;
  final AnalysisClassification classification;

  MoveAnalysis({
    required this.moveNumber,
    required this.san,
    required this.fenBeforeMove,
    required this.fenAfterMove,
    required this.bestMove,
    required this.playedMove,
    required this.evaluation,
    required this.centipawnLoss,
    required this.classification,
  });

  bool get isCritical =>
      classification == AnalysisClassification.mistake ||
      classification == AnalysisClassification.blunder;

  factory MoveAnalysis.fromJson(Map<String, dynamic> json) => MoveAnalysis(
    moveNumber: json['moveNumber'] as int,
    san: (json['san'] as String?) ?? '',
    fenBeforeMove: (json['fenBeforeMove'] as String?) ?? '',
    fenAfterMove: (json['fenAfterMove'] as String?) ?? '',
    bestMove: (json['bestMove'] as String?) ?? '',
    playedMove: (json['playedMove'] as String?) ?? '',
    evaluation: (json['evaluation'] as num?)?.toDouble() ?? 0,
    centipawnLoss: (json['centipawnLoss'] as num?)?.toDouble() ?? 0,
    classification: _analysisClassificationFromJson(json['classification']),
  );
}

class GameAnalysis {
  final String gameId;
  final ApiGameResult? result;
  final int moveCount;
  final List<MoveAnalysis> moves;

  GameAnalysis({
    required this.gameId,
    required this.result,
    required this.moveCount,
    required this.moves,
  });

  factory GameAnalysis.fromJson(Map<String, dynamic> json) => GameAnalysis(
    gameId: json['gameId'] as String,
    result: _resultFromJson(json['result']),
    moveCount: (json['moveCount'] as int?) ?? 0,
    moves: ((json['moves'] as List?) ?? const [])
        .map((item) => MoveAnalysis.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
