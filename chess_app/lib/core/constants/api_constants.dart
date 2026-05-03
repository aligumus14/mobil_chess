class ApiConstants {
  // Web icin yerel HTTP endpoint kullanilir.
  static const String baseUrlWeb = 'http://localhost:5196/api';

  // Android emulator host makinenin localhost'una 10.0.2.2 ile erisir.
  static const String baseUrlAndroid = 'http://10.0.2.2:5196/api';

  // Windows/iOS gibi yerel calisma senaryolari.
  static const String baseUrl = 'http://localhost:5196/api';

  // Auth endpoints
  static const String register = '/Auth/register';
  static const String login = '/Auth/login';

  // User endpoints
  static const String userProfile = '/Users/profile';

  // Game endpoints
  static const String games = '/Games';
  static const String myGames = '/Games/me';
  static String gameById(String id) => '/Games/$id';
  static String analysisGame(String id) => '/Analysis/game/$id';
  static const String engineBestMove = '/Engine/best-move';

  // Matchmaking endpoints
  static const String matchmakingJoin = '/Matchmaking/join';
  static const String matchmakingLeave = '/Matchmaking/leave';
  static const String matchmakingStatus = '/Matchmaking/status';

  // Hub endpoint (no /api prefix)
  static const String gameHubWeb = 'http://localhost:5196/hubs/game';
  static const String gameHubAndroid = 'http://10.0.2.2:5196/hubs/game';
  static const String gameHub = 'http://localhost:5196/hubs/game';
}
