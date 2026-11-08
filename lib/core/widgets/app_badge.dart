import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppBadgeType { primary, lime, success, warning, danger, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppBadgeType type;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = AppBadgeType.neutral,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (type) {
      case AppBadgeType.primary:
        bg = APColors.blueSurface;
        fg = APColors.blue;
        border = Border.all(color: APColors.blue.withValues(alpha: 0.25));
        break;
      case AppBadgeType.lime:
        bg = APColors.limeLight;
        fg = APColors.ink;
        border = Border.all(color: APColors.limeDark);
        break;
      case AppBadgeType.success:
        bg = APColors.successLight;
        fg = APColors.success;
        border = Border.all(color: APColors.success.withValues(alpha: 0.3));
        break;
      case AppBadgeType.warning:
        bg = APColors.warningLight;
        fg = const Color(0xFFB45309);
        border = Border.all(color: APColors.warning.withValues(alpha: 0.35));
        break;
      case AppBadgeType.danger:
        bg = APColors.dangerLight;
        fg = APColors.danger;
        border = Border.all(color: APColors.danger.withValues(alpha: 0.35));
        break;
      case AppBadgeType.neutral:
        bg = APColors.surface;
        fg = APColors.inkSecondary;
        border = Border.all(color: APColors.line);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

