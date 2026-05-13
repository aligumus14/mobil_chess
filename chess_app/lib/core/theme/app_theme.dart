import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF11100E);
  static const backgroundAlt = Color(0xFF181713);
  static const surface = Color(0xFF22201C);
  static const surfaceStrong = Color(0xFF2D2A25);
  static const surfaceSoft = Color(0xFF1B1A17);
  static const primary = Color(0xFF86C342);
  static const primaryDark = Color(0xFF5E8F31);
  static const accent = Color(0xFF8BCB45);
  static const accentDark = Color(0xFF6FA737);
  static const error = Color(0xFFFF5956);
  static const warning = Color(0xFFFFB447);
  static const success = Color(0xFF86C342);
  static const textPrimary = Color(0xFFF0E9DD);
  static const textSecondary = Color(0xFFB8AEA1);
  static const textMuted = Color(0xFF81786D);
  static const divider = Color(0xFF3A362F);
  static const boardLight = Color(0xFFE8D1A8);
  static const boardDark = Color(0xFFB98358);
}

class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceStrong;
  final Color surfaceSoft;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color accentDark;
  final Color error;
  final Color warning;
  final Color success;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color boardLight;
  final Color boardDark;

  const AppPalette({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceStrong,
    required this.surfaceSoft,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.accentDark,
    required this.error,
    required this.warning,
    required this.success,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.boardLight,
    required this.boardDark,
  });

  static const dark = AppPalette(
    background: AppColors.background,
    backgroundAlt: AppColors.backgroundAlt,
    surface: AppColors.surface,
    surfaceStrong: AppColors.surfaceStrong,
    surfaceSoft: AppColors.surfaceSoft,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    accent: AppColors.accent,
    accentDark: AppColors.accentDark,
    error: AppColors.error,
    warning: AppColors.warning,
    success: AppColors.success,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    divider: AppColors.divider,
    boardLight: AppColors.boardLight,
    boardDark: AppColors.boardDark,
  );

  static const light = AppPalette(
    background: Color(0xFFF4F0E8),
    backgroundAlt: Color(0xFFECE4D7),
    surface: Color(0xFFFFFCF6),
    surfaceStrong: Color(0xFFE8DEC9),
    surfaceSoft: Color(0xFFF8F1E5),
    primary: Color(0xFF6FA737),
    primaryDark: Color(0xFF547E2B),
    accent: Color(0xFF7FBF3F),
    accentDark: Color(0xFF5E912E),
    error: Color(0xFFD64743),
    warning: Color(0xFFB56C12),
    success: Color(0xFF5F9D33),
    textPrimary: Color(0xFF24211D),
    textSecondary: Color(0xFF675F54),
    textMuted: Color(0xFF8F8577),
    divider: Color(0xFFD8CCB8),
    boardLight: Color(0xFFE8D1A8),
    boardDark: Color(0xFFB98358),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceStrong,
    Color? surfaceSoft,
    Color? primary,
    Color? primaryDark,
    Color? accent,
    Color? accentDark,
    Color? error,
    Color? warning,
    Color? success,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? boardLight,
    Color? boardDark,
  }) {
    return AppPalette(
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      boardLight: boardLight ?? this.boardLight,
      boardDark: boardDark ?? this.boardDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      backgroundAlt: Color.lerp(backgroundAlt, other.backgroundAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      boardLight: Color.lerp(boardLight, other.boardLight, t)!,
      boardDark: Color.lerp(boardDark, other.boardDark, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

class AppTheme {
  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: 1.2),
    );

    return base.copyWith(
      extensions: [palette],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.accent,
        onSecondary: Colors.white,
        error: palette.error,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      dividerColor: palette.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: palette.textPrimary, size: 30),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.surfaceStrong,
          disabledForegroundColor: palette.textMuted,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.surfaceStrong,
          disabledForegroundColor: palette.textMuted,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.divider),
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        labelStyle: TextStyle(color: palette.textSecondary),
        hintStyle: TextStyle(color: palette.textMuted),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        border: inputBorder(palette.divider),
        enabledBorder: inputBorder(palette.divider),
        focusedBorder: inputBorder(palette.primary),
        errorBorder: inputBorder(palette.error),
        focusedErrorBorder: inputBorder(palette.error),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceStrong,
        selectedColor: palette.primary,
        disabledColor: palette.surfaceSoft,
        labelStyle: TextStyle(color: palette.textPrimary),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: BorderSide(color: palette.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(
          color: palette.textSecondary,
          fontSize: 15,
          height: 1.35,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceStrong,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.background,
        indicatorColor: palette.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? palette.primary
                : palette.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.primary
                : palette.textSecondary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
