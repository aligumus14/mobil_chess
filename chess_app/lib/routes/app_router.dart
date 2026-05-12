import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/provider/auth_providers.dart';
import '../features/analysis/view/game_analysis_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/register_screen.dart';
import '../features/game_history/view/game_detail_screen.dart';
import '../features/game_history/view/game_history_screen.dart';
import '../features/home/view/home_screen.dart';
import '../features/offline_game/setup/game_setup_screen.dart';
import '../features/offline_game/view/offline_game_screen.dart';
import '../features/online_game/view/matchmaking_screen.dart';
import '../features/online_game/view/online_game_screen.dart';
import '../features/profile/view/profile_screen.dart';
import '../features/splash/view/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final status = authState.status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      final loggingIn = loc == '/login' || loc == '/register';
      final onSplash = loc == '/splash';

      if (status == AuthStatus.unauthenticated) {
        if (onSplash || !loggingIn) return '/login';
        return null;
      }

      if (status == AuthStatus.authenticated) {
        if (loggingIn || onSplash) return '/home';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/games', builder: (_, __) => const GameHistoryScreen()),
      GoRoute(
        path: '/games/:id',
        builder: (_, state) =>
            GameDetailScreen(gameId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/games/:id/analysis',
        builder: (_, state) =>
            GameAnalysisScreen(gameId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/offline-setup',
        builder: (_, __) => const GameSetupScreen(),
      ),
      GoRoute(
        path: '/offline-game',
        builder: (_, __) => const OfflineGameScreen(),
      ),
      GoRoute(
        path: '/matchmaking',
        builder: (_, __) => const MatchmakingScreen(),
      ),
      GoRoute(
        path: '/online-game/:id',
        builder: (_, state) =>
            OnlineGameScreen(gameId: state.pathParameters['id']!),
      ),
    ],
  );
});
