import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';
import 'ap_banners.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 220,
                height: 130,
                child: APPhoto(
                  asset: 'assets/images/court1.jpg',
                  alignment: Alignment(0, .55),
                  scrim: .25,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                fontSize: 20.7,
                fontWeight: FontWeight.w800,
                color: APColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style:  TextStyle(
                fontSize: 14,
                color: APColors.slate,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.primary,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

