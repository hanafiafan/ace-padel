import 'core/widgets/ap_shape.dart';
import 'core/widgets/ap_banners.dart';
import 'core/utils/ui.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/widgets/ap_decor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/formatters.dart';
import 'core/utils/haptics.dart';
import 'data.dart';
import 'store.dart';

/// Horizontal "featured" court card used on Home.
class FeaturedCard extends StatelessWidget {
  final Court court;
  final VoidCallback onTap;
  const FeaturedCard({super.key, required this.court, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        APHaptics.light();
        onTap();
      },
      child: Container(
        width: 275,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: APShadows.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              apImg(
court.image, fallbackUrl: court.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: court.gradient),
                  ),
                ),
              ),
              // Multi-stop gradient overlay for superior text contrast
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      court.gradient.first.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _glassPill(court.indoor ? 'Indoor' : 'Outdoor'),
                        const Spacer(),
                        AnimatedBuilder(
                          animation: FavoriteStore.instance,
                          builder: (_, __) {
                            final isFav =
                                FavoriteStore.instance.isFavorite(court.id);
                            return GestureDetector(
                              onTap: () {
                                APHaptics.medium();
                                toggleFavorite(context, court.id);
                              },
                              child: AnimatedScale(
                                scale: isFav ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.elasticOut,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Icon(
                                    isFav
                                        ? LucideIcons.heart
                                        : LucideIcons.heart,
                                    color:
                                        isFav ? Colors.redAccent : Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.star, color: APColors.lime, size: 16),
                              const SizedBox(width: 3),
                              Text(
                                '${court.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      court.name,
                      style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                        color: Colors.white,
                        fontSize: 22.4,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            court.venue,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '•  1.5 km',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                APFormatters.idrCompact(court.pricePerHour),
                                style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                                  color: Colors.white,
                                  fontSize: 20.7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' / jam',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: APColors.lime,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x35C7F23C),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child:  const Icon(
                            LucideIcons.arrowRight,
                            color: AP.onLime,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassPill(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: APColors.lime,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: APColors.lime,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact list row used on Courts tab.
class CourtRow extends StatelessWidget {
  final Court court;
  final VoidCallback onTap;
  const CourtRow({super.key, required this.court, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: ShapeDecoration(
        color: AP.surface,
        shape: ChamferBorder(
          br: 18,
          tl: 8,
          side: BorderSide(
            color: APTheme.isDark ? const Color(0xFF1E2A55) : const Color(0xFFE0E5F5),
            width: 1.2,
          ),
        ),
        shadows: [
          BoxShadow(
            color: APColors.blue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            APHaptics.light();
            onTap();
          },
          customBorder: const ChamferBorder(br: 18, tl: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: apImg(
                        court.image,
                        fallbackUrl: court.imageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: court.gradient),
                          ),
                          child: const APRacketIcon(color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: ShapeDecoration(
                          color: APColors.lime,
                          shape: const ChamferBorder(br: 4, tl: 2),
                        ),
                        child: Text(
                          court.indoor ? 'INDOOR' : 'OUTDOOR',
                          style: const TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            color: APColors.onLime,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              court.name,
                              style: TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: APColors.ink,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: FavoriteStore.instance,
                            builder: (_, __) {
                              final isFav = FavoriteStore.instance.isFavorite(court.id);
                              return GestureDetector(
                                onTap: () {
                                  APHaptics.light();
                                  toggleFavorite(context, court.id);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(
                                    isFav ? LucideIcons.heart : LucideIcons.heart,
                                    size: 18,
                                    color: isFav ? Colors.redAccent : APColors.slate,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(LucideIcons.footprints, size: 12, color: APColors.slate),
                          const SizedBox(width: 3),
                          Text(
                            '10 min',
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              color: APColors.slate,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '•  ${court.area}',
                            style: TextStyle(color: APColors.slate, fontSize: 11.5, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Star Rating Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const ShapeDecoration(
                              color: Color(0xFFFEF3C7),
                              shape: ChamferBorder(br: 4, tl: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.star, size: 11, color: Color(0xFFD97706)),
                                const SizedBox(width: 2),
                                Text(
                                  '${court.rating}',
                                  style: const TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Availability slot badge (inspired by Reference 2)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: const ShapeDecoration(
                              color: Color(0xFFE0F2FE),
                              shape: ChamferBorder(br: 4, tl: 2),
                            ),
                            child: Text(
                              court.indoor ? '8 SLOTS READY' : '4 SLOTS READY',
                              style: const TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0369A1),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            APFormatters.idrCompact(court.pricePerHour),
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              color: APColors.blue,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            ' /jam',
                            style: TextStyle(
                              color: APColors.slate,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Original Ace Padel brand lockup: athletic lime shield + padel paddle glyph + wordmark.
class AceLogo extends StatelessWidget {
  final double size;
  const AceLogo({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AceLogoEmblem(size: size, withGlow: true),
        SizedBox(width: size * 0.28),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Display',
                  fontStyle: FontStyle.italic,
                  fontSize: size * 0.65,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
                children: [
                  TextSpan(text: 'ACE', style: TextStyle(color: APColors.ink)),
                  TextSpan(text: 'PADEL', style: TextStyle(color: APColors.blue)),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: ShapeDecoration(
                color: APColors.blueDark,
                shape: const ChamferBorder(br: 4, tl: 4),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontFamily: 'Display',
                  fontStyle: FontStyle.italic,
                  color: APColors.lime,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4.5,
                height: 18,
                decoration: const ShapeDecoration(
                  color: APColors.lime,
                  shape: ChamferBorder(br: 3, tl: 3),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 3.0,
                height: 18,
                decoration: ShapeDecoration(
                  color: APColors.blue,
                  shape: const ChamferBorder(br: 2, tl: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Display',
                fontStyle: FontStyle.italic,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: APColors.ink,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: () {
                APHaptics.light();
                onAction?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: ShapeDecoration(
                  color: APColors.blue.withValues(alpha: 0.1),
                  shape: const ChamferBorder(br: 6, tl: 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action!.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        color: APColors.blue,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(LucideIcons.arrowRight, size: 12, color: APColors.blue),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
