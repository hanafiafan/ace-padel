import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../data.dart';
import '../theme.dart';

void showAchievementDetailModal(BuildContext context, Achievement a) {
  final on = a.unlocked;
  showModalBottomSheet(
    context: context,
    backgroundColor: AP.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AP.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Large glowing badge
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: on ? AP.lime : AP.line,
              shape: BoxShape.circle,
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: AP.lime.withValues(alpha: 0.5),
                        blurRadius: 18,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: APGlyph(
              a.icon,
              size: 46,
              color: on ? AP.onLime : AP.slate,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            a.title,
            style:  TextStyle(fontFamily: 'Display', 
              fontSize: 22.4,
              fontWeight: FontWeight.w800,
              color: AP.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: on
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              on ? 'TERBUKA • POIN KLAIM +50' : 'TERKUNCI • DALAM PROGRES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: on ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            a.desc,
            textAlign: TextAlign.center,
            style:  TextStyle(color: AP.slate, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (!on) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: a.ratio,
                minHeight: 8,
                backgroundColor: AP.line,
                valueColor:  AlwaysStoppedAnimation(AP.blue),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Progres saat ini: ${a.progress} dari ${a.target} (${(a.ratio * 100).toInt()}%)',
              style:  TextStyle(
                color: AP.slate,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AP.cloud,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AP.line),
              ),
              child:  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.badgeCheck, color: AP.blue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pencapaian aktif di profil Anda',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AP.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: on ? AP.lime : AP.blue,
                foregroundColor: on ? AP.onLime : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                on ? 'Tutup' : 'Mengerti',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Compact achievement badge, reused in Profile and the full screen.
class AchievementBadge extends StatelessWidget {
  final Achievement a;
  final double size;
  const AchievementBadge({super.key, required this.a, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final on = a.unlocked;
    return GestureDetector(
      onTap: () => showAchievementDetailModal(context, a),
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: on ? AP.lime : AP.line,
              shape: BoxShape.circle,
            ),
            child:
                APGlyph(a.icon, color: on ? AP.onLime : AP.slate, size: size * 0.5),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size + 16,
            child: Text(
              a.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: on ? AP.ink : AP.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.unlocked).length;
    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: const Text(
          'Pencapaian',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: APList(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient:  LinearGradient(colors: [AP.blueDark, AP.blue]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.medal, color: AP.lime, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$unlocked dari ${achievements.length} terbuka',
                          style: const TextStyle(fontFamily: 'Display', 
                              color: Colors.white,
                              fontSize: 20.7,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text('Terus main untuk membuka semua badge',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...achievements.map((a) => _AchievementTile(a: a)),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement a;
  const _AchievementTile({required this.a});

  @override
  Widget build(BuildContext context) {
    final on = a.unlocked;
    return GestureDetector(
      onTap: () => showAchievementDetailModal(context, a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AP.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? AP.lime : AP.line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: on ? AP.lime : AP.line, shape: BoxShape.circle),
              child: APGlyph(a.icon, color: on ? AP.onLime : AP.slate),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(a.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                      if (on)
                         Icon(LucideIcons.circleCheck,
                            color: AP.blue, size: 18),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(a.desc,
                      style:  TextStyle(color: AP.slate, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (!on) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: a.ratio,
                        minHeight: 6,
                        backgroundColor: AP.line,
                        valueColor:  AlwaysStoppedAnimation(AP.blue),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${a.progress}/${a.target}',
                        style:  TextStyle(color: AP.slate, fontSize: 11)),
                  ] else
                     Text('Selesai • Ketuk untuk detail',
                        style: TextStyle(
                            color: AP.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
