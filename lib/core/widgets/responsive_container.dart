import 'package:flutter/material.dart';

/// Responsive wrapper that constrains width on tablets and desktops
/// per Flutter layout best practices.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 640.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > maxWidth) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          );
        }
        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

