import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class ChessBackground extends StatelessWidget {
  final Widget child;

  const ChessBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.background,
            colors.backgroundAlt,
            colors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class ChessPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;
  final Border? border;

  const ChessPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.color,
    this.radius = 20,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final panel = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: panel,
      ),
    );
  }
}

class PlayerAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final bool online;
  final Color? backgroundColor;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.radius = 32,
    this.online = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final dotSize = radius * 0.34;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? colors.surfaceStrong,
          child: Text(
            initials(name),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: radius * 0.56,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: radius * 0.06,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: online ? colors.primary : colors.textMuted,
              shape: BoxShape.circle,
              border: Border.all(color: colors.background, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  static String initials(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (parts.first.length >= 2
              ? parts.first.substring(0, 2)
              : parts.first)
          .toUpperCase();
    }
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }
}

class KnightMark extends StatelessWidget {
  final double size;
  final Color color;

  const KnightMark({
    super.key,
    this.size = 34,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return Text(
      String.fromCharCode(0x2658),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color == AppColors.textPrimary ? colors.textPrimary : color,
        fontSize: size,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: colors.primary, size: 28),
          const SizedBox(width: 12),
        ],
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
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final displayColor = color == AppColors.primary
        ? colors.primary
        : color == AppColors.textSecondary
            ? colors.textSecondary
            : color == AppColors.error
                ? colors.error
                : color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: displayColor, size: 30),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: displayColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class ChessBottomNav extends StatelessWidget {
  final int currentIndex;

  const ChessBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavItem(
                iconBuilder: (color) => KnightMark(size: 32, color: color),
                label: 'Oyna',
                active: currentIndex == 0,
                onTap: () => context.go('/home'),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                iconBuilder: (color) =>
                    Icon(Icons.schedule_rounded, color: color, size: 30),
                label: 'Gecmis',
                active: currentIndex == 1,
                onTap: () => context.go('/games'),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                iconBuilder: (color) =>
                    Icon(Icons.person_outline_rounded, color: color, size: 30),
                label: 'Profil',
                active: currentIndex == 2,
                onTap: () => context.go('/profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final Widget Function(Color color) iconBuilder;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.iconBuilder,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.palette;
    final color = active ? colors.primary : colors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: Center(child: iconBuilder(color)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: active ? 58 : 0,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
