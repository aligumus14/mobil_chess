import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemePreference { dark, light }

enum AppLanguagePreference { tr, en }

class AppNotification {
  final String title;
  final String body;
  final DateTime createdAt;

  const AppNotification({
    required this.title,
    required this.body,
    required this.createdAt,
  });
}

class AppSettingsState {
  final AppThemePreference theme;
  final bool notificationsEnabled;
  final AppLanguagePreference language;
  final List<AppNotification> notifications;

  const AppSettingsState({
    this.theme = AppThemePreference.dark,
    this.notificationsEnabled = true,
    this.language = AppLanguagePreference.tr,
    this.notifications = const [],
  });

  AppSettingsState copyWith({
    AppThemePreference? theme,
    bool? notificationsEnabled,
    AppLanguagePreference? language,
    List<AppNotification>? notifications,
  }) {
    return AppSettingsState(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    return const AppSettingsState();
  }

  void setTheme(AppThemePreference theme) {
    state = state.copyWith(theme: theme);
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void setLanguage(AppLanguagePreference language) {
    state = state.copyWith(language: language);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
  AppSettingsNotifier.new,
);
