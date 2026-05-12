class AuthResponseModel {
  final String userId;
  final String username;
  final String email;
  final String token;

  AuthResponseModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        userId: json['userId'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        token: json['token'] as String,
      );
}
