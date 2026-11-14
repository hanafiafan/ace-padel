import 'ap_shape.dart';
import 'ap_decor.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

const _kDisplay = 'Display';

/// Bundled asset (`assets/...`) or a server path (`/img/..`, `/uploads/..`).
ImageProvider apImageProvider(String src) => src.startsWith('assets/')
    ? AssetImage(src) as ImageProvider
    : NetworkImage(ApiService.instance.absUrl(src));

/// Image from a bundled asset when present, else from the server (`fallbackUrl`).
Widget apImg(
  String src, {
  String fallbackUrl = '',
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  final err = errorBuilder ?? (_, __, ___) => const ColoredBox(color: APColors.blueDark);
  if (src.isEmpty && fallbackUrl.isEmpty) return Builder(builder: (c) => err(c, 'empty', null));
  if (src.startsWith('assets/')) {
    return Image.asset(src, width: width, height: height, fit: fit, alignment: alignment,
        errorBuilder: fallbackUrl.isEmpty
            ? err
            : (c, e, s) => Image.network(ApiService.instance.absUrl(fallbackUrl),
                width: width, height: height, fit: fit, alignment: alignment, errorBuilder: err));
  }
  return Image.network(ApiService.instance.absUrl(src.isEmpty ? fallbackUrl : src),
      width: width, height: height, fit: fit, alignment: alignment, errorBuilder: err);
}

/// Photo with a bottom-weighted black scrim, so text on top stays legible.
class APPhoto extends StatelessWidget {
  final String asset;
  final Alignment alignment;
  final double scrim; // 0..1 strength of the dark overlay
  final Widget? child;
  final String fallbackUrl;
  const APPhoto({super.key, required this.asset, this.fallbackUrl = '', this.alignment = Alignment.center, this.scrim = .72, this.child});

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        apImg(asset, fallbackUrl: fallbackUrl, alignment: alignment),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: .08), Colors.black.withValues(alpha: scrim)],
            ),
          ),
        ),
        if (child != null) child!,
      ]);
}

class APBannerData {
  final String asset;
  final String tag;
  final String title;
  final String subtitle;
  final String cta;
  final Alignment alignment;
  final VoidCallback onTap;
  const APBannerData({
    required this.asset,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
    this.alignment = Alignment.center,
  });
}

/// Auto-advancing photo banner carousel with a pill indicator.
class APBannerCarousel extends StatefulWidget {
  final List<APBannerData> banners;
  final double height;
  const APBannerCarousel({super.key, required this.banners, this.height = 184});

  @override
  State<APBannerCarousel> createState() => _APBannerCarouselState();
}

class _APBannerCarouselState extends State<APBannerCarousel> {
  final _c = PageController(viewportFraction: .92);
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_c.hasClients || widget.banners.length < 2) return;
      _c.animateToPage((_i + 1) % widget.banners.length, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: widget.height,
        child: PageView.builder(
          controller: _c,
          itemCount: widget.banners.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, i) {
            final b = widget.banners[i];
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  APHaptics.light();
                  b.onTap();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: APPhoto(
                    asset: b.asset,
                    alignment: b.alignment,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(b.tag.toUpperCase(),
                              style: const TextStyle(color: APColors.lime, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                          const SizedBox(height: 4),
                          Text(b.title,
                              style: const TextStyle(
                                  fontFamily: _kDisplay, color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, height: 1.0)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(
                              child: Text(b.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 13)),
                            ),
                            Text(b.cta, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.arrowRight, color: Colors.white, size: 14),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < widget.banners.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == _i ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _i ? APColors.blue : APColors.lineDark,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ]),
    ]);
  }
}

class APQuickAction {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final String? tag;
  final Color? color;
  const APQuickAction(this.icon, this.label, this.onTap, {this.tag, this.color});
}

/// Four equal actions — sporty chamfered cards with dynamic accents and micro tags.
class APQuickActions extends StatelessWidget {
  final List<APQuickAction> actions;
  const APQuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) => Row(children: [
        for (final a in actions)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  APHaptics.light();
                  a.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF070B1F),
                    shape: ChamferBorder(
                      br: 16,
                      tl: 6,
                      side: BorderSide(
                        color: (a.color ?? APColors.blue).withValues(alpha: 0.5),
                        width: 1.3,
                      ),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  (a.color ?? APColors.blue).withValues(alpha: 0.22),
                                  (a.color ?? APColors.blue).withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (a.color ?? APColors.blue).withValues(alpha: 0.45),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (a.color ?? APColors.blue).withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconTheme(
                              data: IconThemeData(
                                color: a.color ?? APColors.blue,
                                size: 24,
                              ),
                              child: Center(child: a.icon),
                            ),
                          ),
                          if (a.tag != null)
                            Positioned(
                              top: -7,
                              right: -9,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: ShapeDecoration(
                                  color: a.color ?? APColors.blue,
                                  shape: const ChamferBorder(br: 5, tl: 3),
                                  shadows: [
                                    BoxShadow(
                                      color: (a.color ?? APColors.blue).withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  a.tag!,
                                  style: TextStyle(
                                    fontFamily: _kDisplay,
                                    fontStyle: FontStyle.italic,
                                    color: (a.color ?? APColors.blue) == APColors.lime
                                        ? APColors.onLime
                                        : Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${a.label.toUpperCase()} →',
                        style: const TextStyle(
                          fontFamily: _kDisplay,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ]);
}

/// Home header: real court photo, tournament radar badge, greeting, athletic primary action.
class APPhotoHero extends StatelessWidget {
  final String name;
  final String line;
  final String cta;
  final VoidCallback onCta;
  const APPhotoHero({super.key, required this.name, required this.line, required this.cta, required this.onCta});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 220,
          child: APPhoto(
            asset: 'assets/images/banner.jpg',
            alignment: const Alignment(0, .2),
            scrim: .82,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: CustomPaint(
                      painter: CourtLinesPainter(color: Colors.white, stroke: 2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
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
                                      BoxShadow(color: APColors.lime, blurRadius: 6),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'RADAR ARENA • LIVE',
                                  style: TextStyle(
                                    fontFamily: _kDisplay,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'HALO, ${name.toUpperCase()}',
                            style: TextStyle(
                              fontFamily: _kDisplay,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: .85),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SIAP MAIN\nHARI INI?',
                        style: TextStyle(
                          fontFamily: _kDisplay,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: .92,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(LucideIcons.mapPin, color: APColors.lime, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: .9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              APHaptics.medium();
                              onCta();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              decoration: ShapeDecoration(
                                color: APColors.lime,
                                shape: const ChamferBorder(br: 10, tl: 8),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x66D4FF00),
                                    blurRadius: 14,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cta.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: _kDisplay,
                                      fontStyle: FontStyle.italic,
                                      color: APColors.onLime,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(LucideIcons.arrowRight, size: 15, color: APColors.onLime),
                                ],
                              ),
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
