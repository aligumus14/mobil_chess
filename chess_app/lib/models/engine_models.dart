class EngineBestMoveRequest {
  final String fen;
  final String difficulty;

  EngineBestMoveRequest({required this.fen, required this.difficulty});

  Map<String, dynamic> toJson() => {'fen': fen, 'difficulty': difficulty};
}

class EngineBestMoveResponse {
  final String bestMove;
  final double evaluation;
  final int moveTimeMs;
  final int? depth;

  EngineBestMoveResponse({
    required this.bestMove,
    required this.evaluation,
    required this.moveTimeMs,
    required this.depth,
  });

  factory EngineBestMoveResponse.fromJson(Map<String, dynamic> json) =>
      EngineBestMoveResponse(
        bestMove: (json['bestMove'] as String?) ?? '',
        evaluation: (json['evaluation'] as num?)?.toDouble() ?? 0,
        moveTimeMs: (json['moveTimeMs'] as int?) ?? 0,
        depth: json['depth'] as int?,
      );
}
