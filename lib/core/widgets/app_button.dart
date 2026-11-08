import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

enum AppButtonVariant { primary, secondary, lime, outline, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 54,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadow;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = enabled ? APColors.blue : APColors.line;
        fg = enabled ? Colors.white : APColors.slate;
        shadow = enabled ? APShadows.primaryButton : null;
        break;
      case AppButtonVariant.lime:
        bg = enabled ? APColors.lime : APColors.line;
        fg = enabled ? APColors.onLime : APColors.slate;
        shadow = enabled ? APShadows.limeButton : null;
        break;
      case AppButtonVariant.secondary:
        bg = enabled ? APColors.blueDark : APColors.line;
        fg = enabled ? Colors.white : APColors.slate;
        break;
      case AppButtonVariant.outline:
        bg = AP.surface;
        fg = enabled ? APColors.blue : APColors.slate;
        border = Border.all(color: enabled ? APColors.blue : APColors.line, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = enabled ? APColors.onLime : APColors.slate;
        break;
    }

    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              setState(() => _isPressed = true);
              APHaptics.light();
            }
          : null,
      onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      onTap: enabled
          ? () {
              APHaptics.medium();
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: _isPressed ? null : shadow,
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: fg, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

