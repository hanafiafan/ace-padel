import 'package:flutter/material.dart';

/// Bentuk "sport" ala web: sudut kecil + potongan serong (chamfer) di pojok.
/// [br] = potongan kanan-bawah, [tl] = potongan kiri-atas (dalam logical px).
class ChamferBorder extends OutlinedBorder {
  final double br;
  final double tl;
  const ChamferBorder({this.br = 14, this.tl = 0, super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect r) {
    final p = Path()
      ..moveTo(r.left + tl, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right, r.bottom - br)
      ..lineTo(r.right - br, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + tl)
      ..close();
    return p;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  ChamferBorder copyWith({BorderSide? side}) => ChamferBorder(br: br, tl: tl, side: side ?? this.side);
  @override
  OutlinedBorder scale(double t) => ChamferBorder(br: br * t, tl: tl * t, side: side.scale(t));
}

