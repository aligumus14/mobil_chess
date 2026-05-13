import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chess_ui.dart';
import '../../auth/provider/auth_providers.dart';
import '../../profile/provider/profile_provider.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        tooltip: 'Menu',
        onPressed: () => Scaffold.of(context).openDrawer(),
        icon: const Icon(Icons.menu_rounded, size: 32),
      ),
    );
  }
}

class AppNotificationButton extends ConsumerWidget {
  const AppNotificationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return IconButton(
      tooltip: 'Bildirimler',
      onPressed: () => _showNotifications(context, settings),
      icon: const Icon(Icons.notifications_none_rounded, size: 30),
    );
  }

  void _showNotifications(BuildContext context, AppSettingsState settings) {
    final colors = context.palette;
    final isEnglish = settings.language == AppLanguagePreference.en;
    final title = isEnglish ? 'Notifications' : 'Bildirimler';
    final empty = !settings.notificationsEnabled
        ? (isEnglish ? 'Notifications are off.' : 'Bildirimler kapali.')
        : (isEnglish ? 'No notifications.' : 'Bildirim yok.');

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final notifications = settings.notifications;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (notifications.isEmpty || !settings.notificationsEnabled)
                  ChessPanel(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            empty,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...notifications.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ChessPanel(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.body,
                              style: TextStyle(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ChessAppDrawer extends ConsumerWidget {
  final int currentIndex;

  const ChessAppDrawer({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.palette;
    final profileAsync = ref.watch(profileProvider);
    final settings = ref.watch(appSettingsProvider);
    final isEnglish = settings.language == AppLanguagePreference.en;

    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(280.0, 340.0).toDouble(),
      backgroundColor: colors.background,
      child: ChessBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              Row(
                children: [
                  const KnightMark(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ChessApp',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isEnglish ? 'Close' : 'Kapat',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              profileAsync.when(
                data: (user) => _DrawerProfile(
                  username: user.username,
                  elo: user.elo,
                ),
                loading: () => const _DrawerLoadingProfile(),
                error: (_, __) => _DrawerGuestProfile(isEnglish: isEnglish),
              ),
              const SizedBox(height: 22),
              _DrawerItem(
                icon: Icons.home_rounded,
                title: isEnglish ? 'Home' : 'Ana Sayfa',
                selected: currentIndex == 0,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
              ),
              _DrawerItem(
                icon: Icons.smart_toy_outlined,
                title: isEnglish ? 'Play Bot' : 'Botla Oyna',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/offline-setup');
                },
              ),
              _DrawerItem(
                icon: Icons.history_rounded,
                title: isEnglish ? 'Game History' : 'Oyun Gecmisi',
                selected: currentIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/games');
                },
              ),
              _DrawerItem(
                icon: Icons.person_outline_rounded,
                title: isEnglish ? 'Profile' : 'Profil',
                selected: currentIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              _DrawerInfoRow(
                icon: Icons.palette_outlined,
                title: isEnglish ? 'Theme' : 'Tema',
                value: _themeLabel(settings.theme, isEnglish),
                onTap: () => _showThemeSheet(context, ref, settings),
              ),
              _DrawerInfoRow(
                icon: Icons.notifications_none_rounded,
                title: isEnglish ? 'Notifications' : 'Bildirimler',
                value: settings.notificationsEnabled
                    ? (isEnglish ? 'On' : 'Acik')
                    : (isEnglish ? 'Off' : 'Kapali'),
                onTap: () {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setNotificationsEnabled(!settings.notificationsEnabled);
                },
              ),
              _DrawerInfoRow(
                icon: Icons.language_rounded,
                title: isEnglish ? 'Language' : 'Dil',
                value: isEnglish ? 'English' : 'Turkce',
                onTap: () => _showLanguageSheet(context, ref, settings),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(isEnglish ? 'Sign Out' : 'Cikis Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(AppThemePreference theme, bool isEnglish) {
    return switch (theme) {
      AppThemePreference.dark => isEnglish ? 'Dark' : 'Koyu',
      AppThemePreference.light => isEnglish ? 'Light' : 'Acik',
    };
  }

  void _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) {
    final isEnglish = settings.language == AppLanguagePreference.en;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingChoice(
                title: isEnglish ? 'Dark' : 'Koyu',
                selected: settings.theme == AppThemePreference.dark,
                onTap: () {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setTheme(AppThemePreference.dark);
                  Navigator.pop(context);
                },
              ),
              _SettingChoice(
                title: isEnglish ? 'Light' : 'Acik',
                selected: settings.theme == AppThemePreference.light,
                onTap: () {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setTheme(AppThemePreference.light);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingChoice(
                title: 'Turkce',
                selected: settings.language == AppLanguagePreference.tr,
                onTap: () {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setLanguage(AppLanguagePreference.tr);
                  Navigator.pop(context);
                },
              ),
              _SettingChoice(
                title: 'English',
                selected: settings.language == AppLanguagePreference.en,
                onTap: () {
                  ref
                      .read(appSettingsProvider.notifier)
                      .setLanguage(AppLanguagePreference.en);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerProfile extends StatelessWidget {
  final String username;
  final int elo;

  const _DrawerProfile({required this.username, required this.elo});

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return ChessPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          PlayerAvatar(name: username, radius: 38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$elo',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.signal_cellular_alt_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerLoadingProfile extends StatelessWidget {
  const _DrawerLoadingProfile();

  @override
  Widget build(BuildContext context) {
    return const ChessPanel(
      child: Row(
        children: [
          PlayerAvatar(name: '...', radius: 34, online: false),
          SizedBox(width: 14),
          Expanded(child: LinearProgressIndicator()),
        ],
      ),
    );
  }
}

class _DrawerGuestProfile extends StatelessWidget {
  final bool isEnglish;

  const _DrawerGuestProfile({required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return ChessPanel(
      child: Row(
        children: [
          const PlayerAvatar(name: 'AG', radius: 34, online: false),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isEnglish ? 'Profile unavailable' : 'Profil yuklenemedi',
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final color = selected ? colors.primary : colors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.14)
            : colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DrawerInfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: colors.textSecondary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingChoice extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SettingChoice({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? colors.primary : colors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
