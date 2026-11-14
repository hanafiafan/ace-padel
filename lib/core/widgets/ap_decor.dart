import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Staggered entrance: fade + slide up. Usage: `widget.reveal(2)`.
extension APReveal on Widget {
  Widget reveal([int i = 0, double dy = 0.12]) => animate()
      .fadeIn(duration: 380.ms, delay: (60 * i).ms, curve: Curves.easeOut)
      .slideY(begin: dy, end: 0, duration: 420.ms, delay: (60 * i).ms, curve: Curves.easeOutCubic);

  Widget popIn([int i = 0]) => animate()
      .fadeIn(duration: 300.ms, delay: (60 * i).ms)
      .scale(begin: const Offset(.85, .85), duration: 380.ms, delay: (60 * i).ms, curve: Curves.easeOutBack);
}

/// Vector top-down padel court (outline, service lines, net).
class CourtLinesPainter extends CustomPainter {
  final Color color;
  final double stroke;
  const CourtLinesPainter({this.color = Colors.white, this.stroke = 1.6});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(10));
    canvas.drawRRect(r, p);
    // net
    canvas.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p..strokeWidth = stroke * 1.6);
    p.strokeWidth = stroke;
    // service lines (6.95m of 10m each side → ~0.3 / 0.7)
    canvas.drawLine(Offset(0, s.height * .27), Offset(s.width, s.height * .27), p);
    canvas.drawLine(Offset(0, s.height * .73), Offset(s.width, s.height * .73), p);
    // centre service line
    canvas.drawLine(Offset(s.width / 2, s.height * .27), Offset(s.width / 2, s.height * .73), p);
  }

  @override
  bool shouldRepaint(covariant CourtLinesPainter o) => o.color != color || o.stroke != stroke;
}

/// Vector padel ball with seam.
class PadelBall extends StatelessWidget {
  final double size;
  const PadelBall({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _BallPainter());
}

class _BallPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.width / 2;
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.4),
          colors: [Color(0xFFE9FF7A), APColors.lime, APColors.limeDark],
        ).createShader(Rect.fromCircle(center: ctr, radius: r)),
    );
    final seam = Paint()
      ..color = Colors.white.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .1;
    c.drawArc(Rect.fromCircle(center: ctr.translate(-r * 1.05, 0), radius: r * .95), -.9, 1.8, false, seam);
    c.drawArc(Rect.fromCircle(center: ctr.translate(r * 1.05, 0), radius: r * .95), math.pi - .9, 1.8, false, seam);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Vector padel racket.
class PadelRacket extends StatelessWidget {
  final double size;
  final Color color;
  const PadelRacket({super.key, this.size = 56, this.color = Colors.white});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * .6, size), painter: _RacketPainter(color));
}

class _RacketPainter extends CustomPainter {
  final Color color;
  _RacketPainter(this.color);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .08
      ..strokeCap = StrokeCap.round;
    final head = Rect.fromLTWH(0, 0, s.width, s.height * .66);
    c.drawRRect(RRect.fromRectAndRadius(head, Radius.circular(s.width * .5)), p);
    c.drawLine(Offset(s.width / 2, head.bottom), Offset(s.width / 2, s.height), p..strokeWidth = s.width * .14);
    final dots = Paint()..color = color.withValues(alpha: .7);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        c.drawCircle(Offset(s.width * (.28 + .22 * i), s.height * (.16 + .13 * j)), s.width * .035, dots);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Navy gradient hero with court lines, glow blobs and floating balls.
/// Put it as the background of any header: `APHero(height: 220, child: ...)`.
class APHero extends StatelessWidget {
  final Widget? child;
  final double? height;
  final BorderRadius radius;
  const APHero({
    super.key,
    this.child,
    this.height,
    this.radius = const BorderRadius.vertical(bottom: Radius.circular(32)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [APColors.blueDark, const Color(0xFF0F1A6B), APColors.blue],
          ),
        ),
        child: Stack(
          children: [
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

/// Soft decorative blob + court-lines backdrop for light screens.
class APSoftBackdrop extends StatelessWidget {
  const APSoftBackdrop({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(children: [
          Positioned(
            right: -20,
            top: 0,
            child: SizedBox(
              width: 170,
              height: 150,
              child: CustomPaint(painter: StripesPainter(APColors.lime.withValues(alpha: .55))),
            ),
          ),
          Positioned(
            left: -80,
            top: 160,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: APColors.blue.withValues(alpha: .06)),
            ),
          ),
        ]),
      );
}

/// Drop-in `ListView(children: …)` whose children reveal with a stagger.
class APList extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final List<Widget> children;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  /// Adds pull-to-refresh.
  final Future<void> Function()? onRefresh;
  const APList({super.key, this.padding, required this.children, this.shrinkWrap = false, this.physics, this.controller, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: onRefresh != null ? const AlwaysScrollableScrollPhysics() : physics,
      controller: controller,
      children: [for (var i = 0; i < children.length; i++) children[i].reveal(math.min(i, 8))],
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Slanted speed stripes — the "sporty" signature motif.
class StripesPainter extends CustomPainter {
  final Color color;
  const StripesPainter(this.color);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    for (var i = 0; i < 3; i++) {
      final x = s.width * (.30 + i * .24);
      final w = s.width * (i == 1 ? .06 : .13);
      c.drawPath(
        Path()
          ..moveTo(x + s.height * .45, 0)
          ..lineTo(x + s.height * .45 + w, 0)
          ..lineTo(x + w, s.height)
          ..lineTo(x, s.height)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StripesPainter o) => o.color != color;
}

/// Ikon raket padel (digambar sendiri; Lucide tidak punya). Dipakai seperti
/// `Icon`: warna & ukuran default mengikuti IconTheme, jadi aman di NavigationBar.
class APRacketIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  const APRacketIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final t = IconTheme.of(context);
    final s = size ?? t.size ?? 24;
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: s,
        child: CustomPaint(painter: _RacketIconPainter(color ?? t.color ?? Colors.black, s)),
      ),
    );
  }
}

class _RacketIconPainter extends CustomPainter {
  final Color color;
  final double s;
  _RacketIconPainter(this.color, this.s);

  @override
  void paint(Canvas c, Size size) {
    final w = s / 12; // 2px pada ukuran 24
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.save();
    c.translate(s / 2, s / 2);
    c.rotate(math.pi / 8); // Dinamis 22.5 derajat sudut smash
    c.translate(-s / 2, -s / 2);

    // Kepala raket: bentuk diamond/teardrop padel modern
    final head = Path()
      ..moveTo(s * .5, s * .04)
      ..cubicTo(s * .86, s * .04, s * .90, s * .42, s * .62, s * .64)
      ..lineTo(s * .38, s * .64)
      ..cubicTo(s * .10, s * .42, s * .14, s * .04, s * .5, s * .04)
      ..close();
    c.drawPath(head, p);

    // Aerodynamic bridge/throat
    final bridge = Path()
      ..moveTo(s * .42, s * .64)
      ..lineTo(s * .46, s * .72)
      ..moveTo(s * .58, s * .64)
      ..lineTo(s * .54, s * .72);
    c.drawPath(bridge, p..strokeWidth = w * 0.9);

    // Grip handle bertekstur
    final fill = Paint()..color = color;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * .43, s * .72, s * .14, s * .25), Radius.circular(s * .03)),
      fill,
    );

    // Lubang perforasi sweet-spot (5 lubang)
    for (final o in [
      const Offset(.38, .20),
      const Offset(.62, .20),
      const Offset(.50, .32),
      const Offset(.38, .44),
      const Offset(.62, .44),
    ]) {
      c.drawCircle(Offset(s * o.dx, s * o.dy), w * .48, fill);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _RacketIconPainter o) => o.color != color || o.s != s;
}

/// Emblem resmi Ace Padel: Chamfer shield volt-lime dengan siluet raket padel
/// berlubang dan aksen bola kinetik melesat.
class AceLogoEmblem extends StatelessWidget {
  final double size;
  final bool withGlow;
  const AceLogoEmblem({super.key, this.size = 36, this.withGlow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAFF66), APColors.lime, Color(0xFFA6CC00)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: APColors.lime.withValues(alpha: 0.55),
                  blurRadius: size * 0.45,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                ),
              ],
      ),
      child: Center(
        child: SizedBox.square(
          dimension: size * 0.62,
          child: CustomPaint(
            painter: _RacketIconPainter(const Color(0xFF070B24), size * 0.62),
          ),
        ),
      ),
    );
  }
}

/// Penanda ikon khusus (Lucide tidak punya raket/bola padel). Dipakai di data
/// yang bertipe IconData; tampilkan lewat [APGlyph].
const kRacketIcon = IconData(0xE9A01);
const kBallIcon = IconData(0xE9A02);

/// `Icon` yang paham [kRacketIcon]/[kBallIcon]; selain itu sama dengan Icon biasa.
class APGlyph extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  const APGlyph(this.icon, {super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    if (icon == kRacketIcon) return APRacketIcon(color: color, size: size);
    if (icon == kBallIcon) return APBallIcon(color: color, size: size);
    return Icon(icon, color: color, size: size);
  }
}

/// Bola tenis/padel: lingkaran dengan dua jahitan melengkung.
class APBallIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  const APBallIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final t = IconTheme.of(context);
    final s = size ?? t.size ?? 24;
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: s,
        child: CustomPaint(painter: _BallIconPainter(color ?? t.color ?? Colors.black, s)),
      ),
    );
  }
}

class _BallIconPainter extends CustomPainter {
  final Color color;
  final double s;
  _BallIconPainter(this.color, this.s);

  @override
  void paint(Canvas c, Size size) {
    final w = s / 12;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final r = s / 2 - w / 2;
    final ctr = Offset(s / 2, s / 2);
    c.drawCircle(ctr, r, p);
    // jahitan: dua busur dari lingkaran bantu di kiri & kanan, dipotong oleh bola
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: ctr, radius: r)));
    c.drawCircle(Offset(s * -.18, s * .5), s * .62, p);
    c.drawCircle(Offset(s * 1.18, s * .5), s * .62, p);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _BallIconPainter o) => o.color != color || o.s != s;
}

/// Sporty, high-performance tactical background canvas featuring padel court
/// geometry, speed vector slashes, coordinate marks, and ambient stadium glow.
class SportyCourtBackdrop extends StatelessWidget {
  final Widget child;
  const SportyCourtBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = APTheme.isDark;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _SportyBackdropPainter(
            isDark: isDark,
            primaryColor: APColors.blue,
            accentColor: APColors.lime,
          ),
        ),
        child,
      ],
    );
  }
}

class _SportyBackdropPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;
  final Color accentColor;

  const _SportyBackdropPainter({
    required this.isDark,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 0. Base Stadium Canvas Fill - Athletic cool-toned arena tone
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF060919) : const Color(0xFFE9EEF9);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 1. Championship Stadium Illumination (Hyper Cobalt top-right, Optic Volt bottom-left)
    final glowPaint = Paint()..style = PaintingStyle.fill;
    
    // Top-right cobalt floodlight
    final trGlow = RadialGradient(
      center: const Alignment(0.9, -0.6),
      radius: 1.3,
      colors: [
        primaryColor.withValues(alpha: isDark ? 0.38 : 0.24),
        primaryColor.withValues(alpha: 0.0),
      ],
    );
    glowPaint.shader = trGlow.createShader(Rect.fromLTWH(0, 0, w, h * 0.75));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.75), glowPaint);

    // Bottom-left optic volt floodlight
    final blGlow = RadialGradient(
      center: const Alignment(-0.8, 0.7),
      radius: 1.2,
      colors: [
        accentColor.withValues(alpha: isDark ? 0.26 : 0.22),
        accentColor.withValues(alpha: 0.0),
      ],
    );
    glowPaint.shader = blGlow.createShader(Rect.fromLTWH(0, h * 0.25, w, h * 0.75));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.25, w, h * 0.75), glowPaint);

    // 2. High-Tech Sport Dot-Matrix Grid (Technical Athletic Canvas)
    final dotColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF1632E6).withValues(alpha: 0.08);
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const dotSpacing = 26.0;
    for (double x = 13; x < w; x += dotSpacing) {
      for (double y = 13; y < h; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    // 3. Vector Tactical Padel Court Blueprint (Prominent & High-Tech)
    final courtLineColor = isDark
        ? accentColor.withValues(alpha: 0.22)
        : primaryColor.withValues(alpha: 0.20);

    final linePaint = Paint()
      ..color = courtLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.square;

    // Tactical Main Court Wireframe
    final courtRect = Rect.fromCenter(
      center: Offset(w * 0.85, h * 0.38),
      width: w * 0.82,
      height: h * 0.48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(courtRect, const Radius.circular(16)),
      linePaint,
    );
    // Outer glass perimeter offset
    canvas.drawRRect(
      RRect.fromRectAndRadius(courtRect.inflate(12), const Radius.circular(20)),
      linePaint..strokeWidth = 1.0..color = courtLineColor.withValues(alpha: isDark ? 0.12 : 0.10),
    );

    linePaint
      ..color = courtLineColor
      ..strokeWidth = 2.0;

    // Net line with center highlight
    final midY = courtRect.top + courtRect.height / 2;
    canvas.drawLine(
      Offset(courtRect.left - 6, midY),
      Offset(courtRect.right + 6, midY),
      linePaint..strokeWidth = 2.8,
    );

    // Service lines (top & bottom boxes)
    final topServiceY = courtRect.top + courtRect.height * 0.28;
    final botServiceY = courtRect.bottom - courtRect.height * 0.28;
    canvas.drawLine(Offset(courtRect.left, topServiceY), Offset(courtRect.right, topServiceY), linePaint..strokeWidth = 1.6);
    canvas.drawLine(Offset(courtRect.left, botServiceY), Offset(courtRect.right, botServiceY), linePaint..strokeWidth = 1.6);

    // Center service line (T-junction)
    canvas.drawLine(
      Offset(courtRect.center.dx, topServiceY),
      Offset(courtRect.center.dx, botServiceY),
      linePaint..strokeWidth = 1.6,
    );

    // 4. Dynamic Racing Velocity Slashes (Top-Right & Bottom-Left)
    final slashPaint = Paint()
      ..color = (isDark ? accentColor : primaryColor).withValues(alpha: isDark ? 0.12 : 0.10)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final startX = w * (0.02 + i * 0.05);
      final slashW = w * 0.022;
      final path = Path()
        ..moveTo(startX + 38, 0)
        ..lineTo(startX + 38 + slashW, 0)
        ..lineTo(startX + slashW, 140)
        ..lineTo(startX, 140)
        ..close();
      canvas.drawPath(path, slashPaint);
    }

    // Secondary angled slash cluster at bottom with accent volt
    for (var i = 0; i < 3; i++) {
      final startX = w * (0.75 + i * 0.07);
      final slashW = w * 0.025;
      final path = Path()
        ..moveTo(startX + 30, h - 120)
        ..lineTo(startX + 30 + slashW, h - 120)
        ..lineTo(startX + slashW, h)
        ..lineTo(startX, h)
        ..close();
      canvas.drawPath(
        path,
        slashPaint..color = (isDark ? primaryColor : accentColor).withValues(alpha: isDark ? 0.15 : 0.14),
      );
    }

    // 5. Tactical Crosshairs (+) & Telemetry Angle Brackets
    final telemetryPaint = Paint()
      ..color = (isDark ? Colors.white : primaryColor).withValues(alpha: isDark ? 0.22 : 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    void drawCrosshair(double x, double y) {
      const len = 8.0;
      canvas.drawLine(Offset(x - len, y), Offset(x + len, y), telemetryPaint);
      canvas.drawLine(Offset(x, y - len), Offset(x, y + len), telemetryPaint);
    }

    void drawBracket(double x, double y, bool isLeft, bool isTop) {
      const size = 12.0;
      final dx = isLeft ? size : -size;
      final dy = isTop ? size : -size;
      canvas.drawLine(Offset(x, y), Offset(x + dx, y), telemetryPaint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy), telemetryPaint);
    }

    drawCrosshair(w * 0.08, h * 0.14);
    drawCrosshair(w * 0.92, h * 0.62);
    drawCrosshair(w * 0.15, h * 0.88);

    // Siku atas dilewati: bertumpuk dengan status bar sistem.
    drawBracket(16, h - 24, true, false);
    drawBracket(w - 16, h - 24, false, false);
  }

  @override
  bool shouldRepaint(covariant _SportyBackdropPainter old) =>
      old.isDark != isDark || old.primaryColor != primaryColor;
}
