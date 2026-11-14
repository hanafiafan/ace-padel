import '../core/widgets/ap_shape.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/ap_banners.dart';
import '../core/widgets/ap_decor.dart';
import '../core/widgets/responsive_container.dart';
import '../core/utils/ui.dart';
import '../data.dart';
import '../widgets.dart';

class MatchStoryShareScreen extends StatefulWidget {
  final Court? court;
  final String? opponent;
  final String? score;

  const MatchStoryShareScreen({
    super.key,
    this.court,
    this.opponent = 'Jack Hunter & Ale Galán',
    this.score = '6-4, 3-6, 7-5',
  });

  @override
  State<MatchStoryShareScreen> createState() => _MatchStoryShareScreenState();
}

class _MatchStoryShareScreenState extends State<MatchStoryShareScreen> {
  bool _usePhotoBg = true;
  bool _showCalories = true;
  bool _showDupr = true;
  int _selectedStyle = 0; // 0: Championship Volt, 1: Pure Obsidian, 2: Royal Cobalt

  @override
  Widget build(BuildContext context) {
    final court = widget.court ?? courts.first;

    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: const Color(0xFF060919),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          leading: const BackButton(color: Colors.white),
          title: const Text(
            'MATCH RECAP // STORY',
            style: TextStyle(
              fontFamily: 'Display',
              fontStyle: FontStyle.italic,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.share2, color: APColors.lime),
              tooltip: 'Bagikan',
              onPressed: () {
                APHaptics.success();
                Clipboard.setData(ClipboardData(
                  text: 'MATCH VICTORY! 🎾 Menang 2-1 di ${court.name} (${court.venue}). DUPR Rating naik +0.18! Main padel seru bareng di Ace Padel: https://acepadel.app/court/${court.id}',
                ));
                showInfo(context, 'Teks & link recap match berhasil disalin ke clipboard!');
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            // Subtitle Guidance
            const Center(
              child: Text(
                'Template pencapaian visual siap bagikan ke Instagram Story & Status',
                style: TextStyle(color: Color(0xFF8E9BB8), fontSize: 11.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // THE STRAVA-GRADE STORY VISUAL WIDGET (Hero Story Canvas)
            Center(
              child: Container(
                width: 320,
                height: 480,
                decoration: ShapeDecoration(
                  color: const Color(0xFF070B1F),
                  shape: const ChamferBorder(
                    br: 24,
                    tl: 14,
                    side: BorderSide(color: Color(0xFF1B2B50), width: 1.4),
                  ),
                  shadows: [
                    BoxShadow(
                      color: APColors.lime.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(14),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image or Deep Gradient
                      if (_usePhotoBg) ...[
                        APPhoto(
                          asset: court.image,
                          fallbackUrl: court.imageUrl,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                const Color(0xFF070B1F).withValues(alpha: 0.94),
                              ],
                              stops: const [0.0, 0.65],
                            ),
                          ),
                        ),
                      ] else ...[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _selectedStyle == 0
                                  ? [const Color(0xFF070B1F), const Color(0xFF132005)]
                                  : (_selectedStyle == 1
                                      ? [const Color(0xFF050711), const Color(0xFF0C1022)]
                                      : [const Color(0xFF070B1F), const Color(0xFF0F1E6D)]),
                            ),
                          ),
                        ),
                      ],

                      // Tactical Blueprint Court Wireframe Overlay
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.08,
                          child: CustomPaint(
                            painter: CourtLinesPainter(color: Colors.white, stroke: 1.5),
                          ),
                        ),
                      ),

                      // Story Overlay Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Bar: Brand Watermark & Match Status
                            Row(
                              children: [
                                const AceLogo(size: 26),
                                const SizedBox(width: 8),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ACE PADEL // TOUR',
                                      style: TextStyle(
                                        fontFamily: 'Display',
                                        fontStyle: FontStyle.italic,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white70,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Text(
                                      'OFFICIAL MATCH RECAP',
                                      style: TextStyle(
                                        fontFamily: 'Display',
                                        fontStyle: FontStyle.italic,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: APColors.lime,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: const ShapeDecoration(
                                    color: APColors.lime,
                                    shape: ChamferBorder(br: 4, tl: 2),
                                  ),
                                  child: const Text(
                                    'VICTORY',
                                    style: TextStyle(
                                      fontFamily: 'Display',
                                      fontStyle: FontStyle.italic,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: APColors.onLime,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Venue & Opponent Tagline
                            Text(
                              court.name.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'vs ${widget.opponent} • 2 Jam Match',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Main Scoreboard Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: ShapeDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: const ChamferBorder(
                                  br: 12,
                                  tl: 6,
                                  side: BorderSide(color: Color(0xFF2A3A60), width: 1.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SET SCORE',
                                        style: TextStyle(
                                          fontFamily: 'Display',
                                          fontStyle: FontStyle.italic,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      Text(
                                        '2 - 1 (WIN)',
                                        style: TextStyle(
                                          fontFamily: 'Display',
                                          fontStyle: FontStyle.italic,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: APColors.lime,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    widget.score!,
                                    style: const TextStyle(
                                      fontFamily: 'Display',
                                      fontStyle: FontStyle.italic,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Strava-Grade Big Telemetry Metrics Grid
                            Row(
                              children: [
                                if (_showDupr)
                                  Expanded(
                                    child: _storyStatBox(
                                      label: 'DUPR RATING',
                                      value: '3.60',
                                      badge: '+0.18 ↑',
                                      badgeColor: APColors.lime,
                                      textColor: APColors.lime,
                                    ),
                                  ),
                                if (_showDupr && _showCalories) const SizedBox(width: 8),
                                if (_showCalories)
                                  Expanded(
                                    child: _storyStatBox(
                                      label: 'CALORIES',
                                      value: '742',
                                      badge: 'KCAL',
                                      badgeColor: const Color(0xFFFF6B00),
                                      textColor: Colors.white,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _storyStatBox(
                                    label: 'AVG PACE',
                                    value: '164',
                                    badge: 'BPM',
                                    badgeColor: const Color(0xFF38BDF8),
                                    textColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Bottom Telemetry Verification Bar
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'MATCH RECAP // ACE PADEL',
                                  style: TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white54,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'acepadel.app',
                                  style: TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: APColors.lime,
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

            const SizedBox(height: 24),

            // Customization Options Controls (Toggle Strava widgets)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: const Color(0xFF0B112C),
                shape: const ChamferBorder(
                  br: 16,
                  tl: 6,
                  side: BorderSide(color: Color(0xFF1E2A4A), width: 1.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KUSTOMISASI TEMPLATE RECAP',
                    style: TextStyle(
                      fontFamily: 'Display',
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _usePhotoBg,
                    onChanged: (v) {
                      APHaptics.light();
                      setState(() => _usePhotoBg = v);
                    },
                    title: const Text('Foto Lapangan Asli sebagai Latar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Gunakan foto pemandangan arena tempat bermain', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    activeThumbColor: APColors.onLime,
                    activeTrackColor: APColors.lime,
                  ),
                  const Divider(color: Color(0xFF1E2A4A), height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _showDupr,
                    onChanged: (v) {
                      APHaptics.light();
                      setState(() => _showDupr = v);
                    },
                    title: const Text('Tampilkan Kenaikan Rating DUPR', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Rating performa +0.18 dari kemenangan pertandingan', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    activeThumbColor: APColors.onLime,
                    activeTrackColor: APColors.lime,
                  ),
                  const Divider(color: Color(0xFF1E2A4A), height: 1),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _showCalories,
                    onChanged: (v) {
                      APHaptics.light();
                      setState(() => _showCalories = v);
                    },
                    title: const Text('Tampilkan Estimasi Kalori Terbakar (KCAL)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Telemetri sensor kebugaran fisik pemain padel', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    activeThumbColor: APColors.onLime,
                    activeTrackColor: APColors.lime,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Share Action Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  APHaptics.success();
                  Clipboard.setData(ClipboardData(
                    text: 'MATCH VICTORY! 🎾 Menang di ${court.name}. DUPR: 3.60 (+0.18). Kalori: 742 KCAL. Cek & booking lapangan di Ace Padel!',
                  ));
                  showInfo(context, 'Story Card siap dibagikan! Info disalin ke clipboard.');
                },
                icon: const Icon(LucideIcons.share2, size: 20),
                label: const Text(
                  'BAGIKAN KE INSTAGRAM STORY & WA',
                  style: TextStyle(
                    fontFamily: 'Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: APColors.lime,
                  foregroundColor: APColors.onLime,
                  elevation: 4,
                  shadowColor: APColors.lime.withValues(alpha: 0.4),
                  shape: const ChamferBorder(br: 12, tl: 6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyStatBox({
    required String label,
    required String value,
    required String badge,
    required Color badgeColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        shape: const ChamferBorder(
          br: 10,
          tl: 4,
          side: BorderSide(color: Color(0xFF243250), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: ShapeDecoration(
                  color: badgeColor,
                  shape: const ChamferBorder(br: 3, tl: 1),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF070B1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Display',
              fontStyle: FontStyle.italic,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
