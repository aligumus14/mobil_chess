import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const ProviderScope(child: ChessApp()));
}

class ChessApp extends ConsumerWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);
    final isLight = settings.theme == AppThemePreference.light;
    return MaterialApp.router(
      title: 'ChessApp',
      debugShowCheckedModeBanner: false,
      theme: isLight ? AppTheme.light : AppTheme.dark,
      routerConfig: router,
    );
  }
}
