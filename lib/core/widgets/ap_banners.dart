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
                  borderRadius: BorderRadius.circular(20),
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
  const APQuickAction(this.icon, this.label, this.onTap);
}

/// Four equal monochrome actions — icon in a white tile, label below.
class APQuickActions extends StatelessWidget {
  final List<APQuickAction> actions;
  const APQuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) => Row(children: [
        for (final a in actions)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                APHaptics.light();
                a.onTap();
              },
              child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AP.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: APColors.line),
                  ),
                  child: IconTheme(
                    data:  IconThemeData(color: APColors.ink, size: 24),
                    child: Center(child: a.icon),
                  ),
                ),
                const SizedBox(height: 8),
                Text(a.label, style:  TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: APColors.inkSecondary)),
              ]),
            ),
          ),
      ]);
}

/// Home header: real court photo, greeting, one primary action.
class APPhotoHero extends StatelessWidget {
  final String name;
  final String line;
  final String cta;
  final VoidCallback onCta;
  const APPhotoHero({super.key, required this.name, required this.line, required this.cta, required this.onCta});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 208,
          child: APPhoto(
            asset: 'assets/images/banner.jpg',
            alignment: const Alignment(0, .2),
            scrim: .8,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('HALO, ${name.toUpperCase()}',
                      style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
                  const SizedBox(height: 4),
                  const Text('Siap main\nhari ini?',
                      style: TextStyle(fontFamily: _kDisplay, color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, height: .95)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Text(line, style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 12.5))),
                    GestureDetector(
                      onTap: () {
                        APHaptics.medium();
                        onCta();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: APColors.lime, borderRadius: BorderRadius.circular(12)),
                        child: Text(cta, style:  TextStyle(color: AP.onLime, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
