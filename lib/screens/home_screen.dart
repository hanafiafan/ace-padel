import '../core/widgets/ap_shape.dart';
import 'package:flutter/material.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/ap_banners.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/responsive_container.dart';
import '../data.dart';
import '../main.dart' show tabIndex;
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';
import 'matches_screen.dart';
import 'coaches_screen.dart';
import 'ticket_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String _cat = 'Semua';
  bool? _indoorFilter;
  int _selectedDayIndex = 0;
  String _tournamentCategory = 'SEMUA';

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    CatalogStore.instance.addListener(_rebuild);
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      CatalogStore.instance.loadAll(),
      MatchStore.instance.refresh(),
      if (UserStore.instance.isLoggedIn) BookingStore.instance.refresh(),
    ]);
  }

  @override
  void dispose() {
    CatalogStore.instance.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  /// Courts for the "nearby" list, filtered by the selected category.
  List<Court> get _byCategory {
    var list = courts;
    if (_indoorFilter != null) {
      list = list.where((c) => c.indoor == _indoorFilter).toList();
    }
    switch (_cat) {
      case 'Indoor':
        return list.where((c) => c.indoor).toList();
      case 'Outdoor':
        return list.where((c) => !c.indoor).toList();
      case 'Terdekat':
        return [...list]..sort((a, b) => b.rating.compareTo(a.rating));
      default: // Semua, Promo
        return list;
    }
  }

  bool _matches(Court c, String q) {
    if (_indoorFilter != null && c.indoor != _indoorFilter) return false;
    return c.name.toLowerCase().contains(q) ||
        c.venue.toLowerCase().contains(q) ||
        c.area.toLowerCase().contains(q) ||
        (c.indoor ? 'indoor' : 'outdoor').contains(q);
  }

  void _openCourt(Court c) {
    APHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(court: c)),
    );
  }

  void _copyPromoCode() {
    APHaptics.success();
    Clipboard.setData(const ClipboardData(text: 'ACEWEEKEND'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(LucideIcons.circleCheck, color: AP.lime, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kode ACEWEEKEND disalin! Diskon Rp25.000 saat booking.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AP.blueDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAdvancedFilterSheet() {
    APHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FILTER & PREFERENSI',
                    style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
                  ),
                  if (_indoorFilter != null)
                    TextButton(
                      onPressed: () {
                        APHaptics.light();
                        setState(() => _indoorFilter = null);
                        setSheetState(() {});
                      },
                      child: const Text('Reset', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
               Text('Tipe Lapangan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AP.slate)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua Tipe'),
                    selected: _indoorFilter == null,
                    onSelected: (val) {
                      APHaptics.light();
                      setState(() => _indoorFilter = null);
                      setSheetState(() {});
                    },
                    selectedColor: AP.blue,
                    labelStyle: TextStyle(
                      color: _indoorFilter == null ? Colors.white : AP.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Indoor (AC)'),
                    selected: _indoorFilter == true,
                    onSelected: (val) {
                      APHaptics.light();
                      setState(() => _indoorFilter = true);
                      setSheetState(() {});
                    },
                    selectedColor: AP.blue,
                    labelStyle: TextStyle(
                      color: _indoorFilter == true ? Colors.white : AP.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Outdoor'),
                    selected: _indoorFilter == false,
                    onSelected: (val) {
                      APHaptics.light();
                      setState(() => _indoorFilter = false);
                      setSheetState(() {});
                    },
                    selectedColor: AP.blue,
                    labelStyle: TextStyle(
                      color: _indoorFilter == false ? Colors.white : AP.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    APHaptics.medium();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    elevation: 0,
                    shape: const ChamferBorder(br: 10, tl: 10),
                  ),
                  child: const Text('Terapkan Filter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final searching = q.isNotEmpty;
    final results =
        searching ? courts.where((c) => _matches(c, q)).toList() : courts;

    return ResponsiveContainer(
      child: SafeArea(
        child: APList(
          onRefresh: _refreshAll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // SOLID ROYAL BLUE ACTION HEADER (Reference 1 Screen 2 & Reference 2 Screen 2)
            Container(
              decoration: const ShapeDecoration(
                color: Color(0xFF1632E6),
                shape: ChamferBorder(br: 24, tl: 8),
                shadows: [
                  BoxShadow(
                    color: Color(0x401632E6),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar + Location + Theme + Bell
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          APHaptics.light();
                          tabIndex.value = 4; // Profil
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: APColors.lime, width: 2),
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.userRound, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Location Dropdown Selector (Reference 2 Screen 1: "London ⌄")
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: ShapeDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: const ChamferBorder(br: 8, tl: 4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.mapPin, color: APColors.lime, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Jakarta Selatan',
                              style: TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(LucideIcons.chevronDown, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Frosted Theme Toggle
                      GestureDetector(
                        onTap: () {
                          APHaptics.light();
                          ThemeController.instance.set(APTheme.isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(APTheme.isDark ? LucideIcons.sun : LucideIcons.moon, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Frosted Bell Button
                      GestureDetector(
                        onTap: () {
                          APHaptics.light();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.bell, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title & Month Selector Row (Reference 1 Screen 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PADEL ARENA ZONE',
                              style: TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                color: APColors.lime,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Padel Action Now',
                              style: TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Month Selector Capsule "< November >"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: ShapeDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: const ChamferBorder(br: 8, tl: 4),
                        ),
                        child: const Text(
                          '‹ Nov 2026 ›',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Horizontal Date Strip on Royal Blue (Reference 1 Screen 2)
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final day = DateTime.now().add(Duration(days: i));
                        final isSel = _selectedDayIndex == i;
                        return GestureDetector(
                          onTap: () {
                            APHaptics.light();
                            setState(() => _selectedDayIndex = i);
                          },
                          child: Container(
                            width: 50,
                            decoration: ShapeDecoration(
                              color: isSel ? APColors.lime : Colors.white.withValues(alpha: 0.12),
                              shape: const ChamferBorder(br: 12, tl: 4),
                              shadows: isSel
                                  ? [
                                      BoxShadow(
                                        color: APColors.lime.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(day).toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? APColors.onLime : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isSel ? APColors.onLime : Colors.white,
                                  ),
                                ),
                                if (isSel)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: const BoxDecoration(
                                      color: APColors.onLime,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tournament Category Filter Chips (Reference 1 Screen 2)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const ShapeDecoration(
                      color: APColors.lime,
                      shape: ChamferBorder(br: 8, tl: 4),
                    ),
                    child: const Icon(LucideIcons.slidersHorizontal, size: 18, color: APColors.onLime),
                  ),
                  for (final cat in ['SEMUA', 'TURNAMEN', 'LIGA', 'FUN GAME', 'OPEN MABAR'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          APHaptics.light();
                          setState(() => _tournamentCategory = cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: ShapeDecoration(
                            color: _tournamentCategory == cat ? APColors.blue : AP.surface,
                            shape: const ChamferBorder(br: 10, tl: 4),
                            shadows: _tournamentCategory == cat ? APShadows.primaryButton : null,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              color: _tournamentCategory == cat ? Colors.white : AP.ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // QUICK START CARD (Inspired by Reference 4 Screen 1)
            GestureDetector(
              onTap: () {
                APHaptics.medium();
                tabIndex.value = 1; // Ke Courts
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: ShapeDecoration(
                  color: APColors.lime,
                  shape: const ChamferBorder(br: 18, tl: 6),
                  shadows: [
                    BoxShadow(
                      color: APColors.lime.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: APColors.onLime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.play, color: APColors.lime, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUICK START // PESAN LAPANGAN',
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                              color: APColors.onLime,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            '16 arena siap tanding • Konfirmasi instan',
                            style: TextStyle(
                              color: Color(0xFF1E2805),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.arrowRight, color: APColors.onLime, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: UserStore.instance,
              builder: (context, _) {
                final user = UserStore.instance.profile;
                return APPhotoHero(
                  name: user.name.split(' ').first,
                  line: '${courts.length} lapangan tersedia',
                  cta: 'Pesan lapangan',
                  onCta: () => tabIndex.value = 1,
                );
              },
            ),

            // Smart Next Match Card (If any active bookings exist)
            AnimatedBuilder(
              animation: BookingStore.instance,
              builder: (context, _) {
                final active = BookingStore.instance.activeBookings;
                if (active.isEmpty) return const SizedBox.shrink();
                final next = active.first;
                final formattedDate = DateFormat('d MMM yyyy').format(next.date);

                return Container(
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F143A), Color(0xFF1E286D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F143A).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AP.lime,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child:  const Text(
                              'JADWAL MAIN ANDA',
                              style: TextStyle(
                                color: AP.onLime,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$formattedDate • ${next.slot} WIB',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: apImg(
next.court.image, fallbackUrl: next.court.imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: next.court.gradient),
                                ),
                                child: const APRacketIcon(color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  next.court.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${next.court.venue} • ${next.court.area}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              APHaptics.light();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketScreen(booking: next),
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.qrCode, size: 14),
                            label: const Text('E-Tiket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AP.lime,
                              foregroundColor: AP.onLime,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: const ChamferBorder(br: 10, tl: 10),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),
            // Sporty Tactical Search & Filter Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: ShapeDecoration(
                      color: AP.surface,
                      shape: const ChamferBorder(br: 14, tl: 6),
                      shadows: APShadows.subtle,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AP.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(LucideIcons.search, color: AP.blue, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (v) => setState(() => _query = v),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(
                              color: AP.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari lapangan atau venue...',
                              hintStyle: TextStyle(
                                color: AP.slate,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (searching)
                          GestureDetector(
                            onTap: () {
                              APHaptics.light();
                              setState(() {
                                _controller.clear();
                                _query = '';
                              });
                            },
                            child: Icon(LucideIcons.x, color: AP.slate, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showAdvancedFilterSheet,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: ShapeDecoration(
                      color: _indoorFilter != null ? AP.blue : AP.surface,
                      shape: const ChamferBorder(br: 14, tl: 6),
                      shadows: _indoorFilter != null
                          ? APShadows.primaryButton
                          : APShadows.subtle,
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.slidersHorizontal,
                        color: _indoorFilter != null ? Colors.white : AP.ink,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 18),

          if (searching) ...[
            SectionHeader('Hasil untuk "${_query.trim()}"'),
            if (results.isEmpty)
              _emptyResults()
            else
              ...results
                  .take(25)
                  .map((c) => CourtRow(court: c, onTap: () => _openCourt(c))),
          ] else ...[
            APQuickActions(actions: [
              APQuickAction(
                const APRacketIcon(),
                'Sewa Court',
                () => tabIndex.value = 1,
                tag: 'BOOK',
                color: AP.blue,
              ),
              APQuickAction(
                const Icon(LucideIcons.swords),
                'Mabar',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchesScreen())),
                tag: 'MATCH',
                color: const Color(0xFF6366F1),
              ),
              APQuickAction(
                const Icon(LucideIcons.medal),
                'Coach',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachesScreen())),
                tag: 'PRO',
                color: const Color(0xFF10B981),
              ),
              APQuickAction(
                const Icon(LucideIcons.zap),
                'Promo',
                _copyPromoCode,
                tag: 'SALE',
                color: const Color(0xFFF59E0B),
              ),
            ]),
            const SizedBox(height: 22),
            APBannerCarousel(banners: [
              APBannerData(
                asset: 'assets/images/court1.jpg',
                alignment: const Alignment(0, .6),
                tag: 'Promo member',
                title: 'Diskon Rp25.000',
                subtitle: 'Akhir pekan • kode ACEWEEKEND',
                cta: 'Salin',
                onTap: _copyPromoCode,
              ),
              APBannerData(
                asset: 'assets/images/court_nine_monas.jpg',
                tag: 'Komunitas',
                title: 'Cari lawan, main bareng',
                subtitle: 'Open match tiap malam',
                cta: 'Lihat mabar',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchesScreen())),
              ),
              APBannerData(
                asset: 'assets/images/court_hpc_atlas_bali.jpg',
                tag: 'Venue pilihan',
                title: 'Main outdoor di Bali',
                subtitle: 'Court dengan view sunset',
                cta: 'Jelajahi',
                onTap: () => tabIndex.value = 1,
              ),
            ]),

            const SizedBox(height: 24),

            // Open Match Highlights section
            SectionHeader(
              'Ayo Mabar Padel',
              action: 'Lihat semua',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MatchesScreen(),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: MatchStore.instance,
              builder: (context, _) {
                final matches = MatchStore.instance.matches;
                if (matches.isEmpty) return const SizedBox.shrink();
                final m = matches.first;

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const ShapeDecoration(
                    color: APColors.lime, // Outer neon-lime container from Reference 1 Screen 2!
                    shape: ChamferBorder(br: 20, tl: 8),
                    shadows: [
                      BoxShadow(
                        color: Color(0x40D4FF00),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const ShapeDecoration(
                      color: Colors.white, // Inner white score panel from Reference 1 Screen 2!
                      shape: ChamferBorder(br: 16, tl: 6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  "GENTLEMEN'S DOUBLES",
                                  style: TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: Color(0xFF1E3A2B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '// ROUND OF 8',
                                  style: TextStyle(
                                    fontFamily: 'Display',
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10.5,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${m.maxPlayers - m.currentPlayers} SLOTS LEFT',
                                style: const TextStyle(
                                  fontFamily: 'Display',
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  color: Color(0xFF065F46),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Teams Lineup
                        Row(
                          children: [
                            // Team 1 (French flag / Team Baseline)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: NetworkImage('https://flagcdn.com/w40/fr.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Flexible(
                                        child: Text(
                                          'Team Baseline',
                                          style: TextStyle(
                                            fontFamily: 'Display',
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13.5,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${m.hostName.split(' ').first} • Juan Lebrón',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Center ball
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: APColors.lime,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'vs',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: APColors.onLime,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Team 2 (USA flag / Team Smashers)
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Team Smashers',
                                          style: TextStyle(
                                            fontFamily: 'Display',
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13.5,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      CircleAvatar(
                                        radius: 11,
                                        backgroundImage: NetworkImage('https://flagcdn.com/w40/us.png'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Jack Hunter • Ale Galán',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Score Tiles Row (Reference 1 Screen 2: [ 6 ] [ 4 ] [ 5 ] vs [ 1 ] [ 6 ] [ 5 ])
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VENUE: ${m.court.name.toUpperCase()}',
                                    style: const TextStyle(
                                      fontFamily: 'Display',
                                      fontStyle: FontStyle.italic,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    'JAM: ${m.time} WIB • Rp${m.pricePerPlayer}k',
                                    style: const TextStyle(
                                      fontFamily: 'Display',
                                      fontStyle: FontStyle.italic,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      color: APColors.blueDark,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _homeScoreTile('6', '1', false),
                                  const SizedBox(width: 5),
                                  _homeScoreTile('4', '6', false),
                                  const SizedBox(width: 5),
                                  _homeScoreTile('5', '5', true),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MatchesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.swords, size: 15),
                            label: Text(
                              'GABUNG OPEN MATCH // TERSISA ${m.maxPlayers - m.currentPlayers} SLOT',
                              style: const TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: APColors.blueDark,
                              foregroundColor: APColors.lime,
                              elevation: 0,
                              shape: const ChamferBorder(br: 8, tl: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            SectionHeader(
              'Pelatih & Coaching Padel',
              action: 'Lihat semua',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CoachesScreen()),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: ShapeDecoration(
                color: AP.surface,
                shape: ChamferBorder(
                  br: 16,
                  tl: 6,
                  side: BorderSide(
                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF10B981).withValues(alpha: 0.22),
                          const Color(0xFF10B981).withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(LucideIcons.graduationCap, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF10B981),
                                shape: const ChamferBorder(br: 4, tl: 2),
                              ),
                              child: const Text(
                                'FIP PRO',
                                style: TextStyle(
                                  fontFamily: 'Display',
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'PRIVATE CLINIC & COACH',
                                style: TextStyle(
                                  fontFamily: 'Display',
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                  color: APColors.ink,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Kuasai teknik dinding & smash bersama pelatih FIP',
                          style: TextStyle(color: AP.slate, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CoachesScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: APColors.lime,
                      foregroundColor: APColors.onLime,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const ChamferBorder(br: 8, tl: 6),
                    ),
                    child: const Text(
                      'BOOK',
                      style: TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SectionHeader('Unggulan',
                action: 'Lihat semua', onAction: () => tabIndex.value = 1),
            SizedBox(
              height: 230,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: courts
                    .take(6)
                    .map((c) =>
                        FeaturedCard(court: c, onTap: () => _openCourt(c)))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Indoor', 'Outdoor', 'Terdekat'].map((cat) {
                  final sel = _cat == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        APHaptics.light();
                        setState(() => _cat = cat);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: ShapeDecoration(
                          color: sel ? AP.blue : AP.surface,
                          shape: const ChamferBorder(br: 10, tl: 6),
                          shadows: sel ? APShadows.primaryButton : APShadows.subtle,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sel) ...[
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: APColors.lime,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              cat.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                color: sel ? Colors.white : APColors.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            SectionHeader(
              _cat == 'Semua' || _cat == 'Promo'
                  ? 'Lapangan terdekat'
                  : 'Lapangan $_cat',
              action: 'Lihat semua',
              onAction: () => tabIndex.value = 1,
            ),
            ..._byCategory
                .take(8)
                .map((c) => CourtRow(court: c, onTap: () => _openCourt(c))),
          ],
        ],
      ),
    ),
  );
}

  Widget _homeScoreTile(String s1, String s2, bool isCurrent) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: ShapeDecoration(
        color: isCurrent ? APColors.lime : const Color(0xFFE2E8F0),
        shape: const ChamferBorder(br: 5, tl: 2),
      ),
      child: Column(
        children: [
          Text(
            s1,
            style: const TextStyle(
              fontFamily: 'Display',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          Container(height: 1, width: 16, color: Colors.black26),
          Text(
            s2,
            style: const TextStyle(
              fontFamily: 'Display',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyResults() =>  Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(LucideIcons.search, size: 56, color: AP.slate),
            const SizedBox(height: 12),
            const Text('Lapangan tidak ditemukan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Coba kata kunci lain, mis. "Jakarta" atau "indoor".',
                textAlign: TextAlign.center,
                style: TextStyle(color: AP.slate)),
          ],
        ),
      );

}

