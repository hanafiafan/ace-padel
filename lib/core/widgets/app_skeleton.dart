import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Daftar kartu placeholder berdenyut selagi data dimuat (tanpa dependensi).
class AppSkeletonList extends StatefulWidget {
  final int count;
  final double itemHeight;
  const AppSkeletonList({super.key, this.count = 4, this.itemHeight = 120});

  @override
  State<AppSkeletonList> createState() => _AppSkeletonListState();
}

class _AppSkeletonListState extends State<AppSkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'Memuat',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: widget.count,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => Container(
            height: widget.itemHeight,
            decoration: BoxDecoration(
              color: Color.lerp(AP.surface, AP.line, reduce ? .5 : .25 + .5 * _c.value),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AP.line),
            ),
          ),
        ),
      ),
    );
  }
}
