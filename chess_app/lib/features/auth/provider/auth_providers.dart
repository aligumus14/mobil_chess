import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/network/api_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../models/auth_response_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/analysis_service.dart';
import '../../../services/engine_service.dart';
import '../../../services/game_history_service.dart';
import '../../../services/game_hub_service.dart';
import '../../../services/matchmaking_service.dart';
import '../../../services/user_service.dart';

// Core providers
final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService(),
);

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(secureStorageProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(apiServiceProvider),
    ref.watch(secureStorageProvider),
  ),
);

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.watch(apiServiceProvider)),
);

final gameHistoryServiceProvider = Provider<GameHistoryService>(
  (ref) => GameHistoryService(ref.watch(apiServiceProvider)),
);

final analysisServiceProvider = Provider<AnalysisService>(
  (ref) => AnalysisService(ref.watch(apiServiceProvider)),
);

final engineServiceProvider = Provider<EngineService>(
  (ref) => EngineService(ref.watch(apiServiceProvider)),
);

final matchmakingServiceProvider = Provider<MatchmakingService>(
  (ref) => MatchmakingService(ref.watch(apiServiceProvider)),
);

final gameHubServiceProvider = Provider<GameHubService>(
  (ref) => GameHubService(ref.watch(secureStorageProvider)),
);

// Auth state
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthResponseModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthResponseModel? user,
    String? errorMessage,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _bootstrap();
    return const AuthState();
  }

  Future<void> _bootstrap() async {
    final loggedIn = await _authService.isLoggedIn();
    if (state.status != AuthStatus.unknown) {
      return;
    }

    state = state.copyWith(
      status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(clearError: true);
    try {
      final user = await _authService.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
