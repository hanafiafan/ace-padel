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
                          child:  Icon(
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
        shape: ChamferBorder(br: 18, side: BorderSide(color: APColors.line)),
        shadows: APShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            APHaptics.light();
            onTap();
          },
          customBorder: const ChamferBorder(br: 18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: apImg(
court.image, fallbackUrl: court.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: court.gradient),
                      ),
                      child: const APRacketIcon(color: Colors.white, size: 28),
                    ),
                  ),
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
                              style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                                fontSize: 18.4,
                                fontWeight: FontWeight.w800,
                                color: APColors.ink,
                                letterSpacing: -0.3,
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
                           Icon(LucideIcons.mapPin, size: 13, color: APColors.slate),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${court.area} • 1.8 km',
                              style:  TextStyle(color: APColors.slate, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.star, size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text(
                                  '${court.rating}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: court.indoor ? APColors.blueSurface : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: court.indoor ? APColors.blue : const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  court.indoor ? 'Indoor' : 'Outdoor',
                                  style: TextStyle(
                                    color: court.indoor ? APColors.blue : const Color(0xFF047857),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            APFormatters.idrCompact(court.pricePerHour),
                            style:  TextStyle(
                              color: APColors.blue,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                           Text(
                            ' /jam',
                            style: TextStyle(
                              color: APColors.slate,
                              fontSize: 11,
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

/// Original Ace Padel brand lockup: lime badge + padel paddle glyph + wordmark.
class AceLogo extends StatelessWidget {
  final double size;
  const AceLogo({super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: APColors.lime,
                borderRadius: BorderRadius.circular(size * 0.28),
              ),
              child: APRacketIcon(size: size * 0.6, color: AP.onLime),
            ),
          ),
        ),
        SizedBox(width: size * 0.26),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: size * 0.54,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
            children:  [
              TextSpan(text: 'Ace', style: TextStyle(color: APColors.ink)),
              TextSpan(text: ' Padel', style: TextStyle(color: APColors.blue)),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                fontSize: 20.7,
                fontWeight: FontWeight.w800,
                color: APColors.ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: () {
                APHaptics.light();
                onAction?.call();
              },
              child: Text(
                action!,
                style:  TextStyle(
                  color: APColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
