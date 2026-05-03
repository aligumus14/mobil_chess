class UserModel {
  final String id;
  final String username;
  final String email;
  final int elo;
  final int wins;
  final int losses;
  final int draws;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.elo,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    elo: json['elo'] as int,
    wins: json['wins'] as int,
    losses: json['losses'] as int,
    draws: json['draws'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  int get totalGames => wins + losses + draws;
  double get winRate => totalGames == 0 ? 0 : (wins / totalGames) * 100;
}
