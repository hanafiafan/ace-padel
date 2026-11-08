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
            colors: [APColors.blueDark, Color(0xFF0F1A6B), APColors.blue],
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
  const APList({super.key, this.padding, required this.children, this.shrinkWrap = false, this.physics, this.controller});

  @override
  Widget build(BuildContext context) => ListView(
        padding: padding,
        shrinkWrap: shrinkWrap,
        physics: physics,
        controller: controller,
        children: [for (var i = 0; i < children.length; i++) children[i].reveal(math.min(i, 8))],
      );
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
    final w = s / 12; // 2px pada ukuran 24, seperti stroke Lucide
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.save();
    c.translate(s / 2, s / 2);
    c.rotate(math.pi / 9); // sedikit miring saja; tegak agar tidak mirip kaca pembesar
    c.translate(-s / 2, -s / 2);
    // kepala: runcing ke leher (siluet raket padel, bukan lingkaran)
    final head = Path()
      ..moveTo(s * .5, s * .03)
      ..cubicTo(s * .88, s * .03, s * .92, s * .42, s * .6, s * .66)
      ..lineTo(s * .4, s * .66)
      ..cubicTo(s * .08, s * .42, s * .12, s * .03, s * .5, s * .03)
      ..close();
    c.drawPath(head, p);
    // gagang tebal (terisi) + garis grip
    final fill = Paint()..color = color;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * .43, s * .68, s * .14, s * .29), Radius.circular(s * .04)),
      fill,
    );
    // 5 lubang, pola seperti ikon aplikasi
    for (final o in [Offset(.38, .17), Offset(.62, .17), Offset(.5, .28), Offset(.4, .4), Offset(.6, .4)]) {
      c.drawCircle(Offset(s * o.dx, s * o.dy), w * .42, fill);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _RacketIconPainter o) => o.color != color || o.s != s;
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
