import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'ap_decor.dart';
import 'ap_shape.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius = 20,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: ShapeDecoration(
        color: color ?? APColors.surface,
        shape: ChamferBorder(br: 16, side: BorderSide(color: APColors.line)),
        shadows: boxShadow ?? APShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return cardContent.reveal();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          APHaptics.light();
          onTap?.call();
        },
        customBorder: const ChamferBorder(br: 16),
        splashColor: APColors.blue.withValues(alpha: 0.08),
        highlightColor: APColors.blue.withValues(alpha: 0.04),
        child: cardContent,
      ),
    ).reveal();
  }
}

