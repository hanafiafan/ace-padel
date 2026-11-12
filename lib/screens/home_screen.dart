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
            // Executive Brand & Action Header
            Row(
              children: [
                const AceLogo(size: 34),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    APHaptics.light();
                    ThemeController.instance.set(APTheme.isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AP.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AP.line),
                    ),
                    child: Icon(APTheme.isDark ? LucideIcons.sun : LucideIcons.moon, color: AP.ink, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    APHaptics.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AP.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AP.line),
                      boxShadow: APShadows.subtle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                         Icon(LucideIcons.bell, color: AP.ink, size: 21),
                        Positioned(
                          top: 8,
                          right: 9,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    APHaptics.light();
                    tabIndex.value = 4; // Ke Profil
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient:  LinearGradient(colors: [AP.blue, AP.blueDark]),
                      shape: BoxShape.circle,
                      border: Border.all(color: AP.lime, width: 2),
                      boxShadow: APShadows.subtle,
                    ),
                    child: const Icon(LucideIcons.userRound, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
            // Upgraded Search & Filter Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AP.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AP.line),
                      boxShadow: APShadows.subtle,
                    ),
                    child: Row(
                      children: [
                         Icon(LucideIcons.search, color: AP.slate, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: (v) => setState(() => _query = v),
                            textInputAction: TextInputAction.search,
                            decoration:  InputDecoration(
                              hintText: 'Cari lapangan atau venue...',
                              hintStyle: TextStyle(color: AP.slate, fontSize: 14),
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
                            child:  Icon(LucideIcons.x, color: AP.slate, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showAdvancedFilterSheet,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _indoorFilter != null ? AP.blue : AP.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _indoorFilter != null ? AP.blue : AP.line,
                      ),
                      boxShadow: APShadows.subtle,
                    ),
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      color: _indoorFilter != null ? Colors.white : AP.ink,
                      size: 22,
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
              APQuickAction(const APRacketIcon(), 'Sewa Court', () => tabIndex.value = 1),
              APQuickAction(const Icon(LucideIcons.users), 'Mabar', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchesScreen()))),
              APQuickAction(const Icon(LucideIcons.graduationCap), 'Coach', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoachesScreen()))),
              APQuickAction(const Icon(LucideIcons.tag), 'Promo', _copyPromoCode),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AP.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AP.line),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: apImg(
m.court.image, fallbackUrl: m.court.imageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: m.court.gradient),
                            ),
                            child: const APRacketIcon(color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m.court.name} • ${m.time}',
                              style:  TextStyle(
                                  color: AP.slate, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.currentPlayers}/${m.maxPlayers} Pemain • Rp${m.pricePerPlayer}k',
                              style:  TextStyle(
                                  color: AP.blue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MatchesScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AP.lime,
                          foregroundColor: AP.onLime,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          elevation: 0,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const ChamferBorder(br: 10, tl: 10),
                        ),
                        child: const Text('Gabung',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AP.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AP.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AP.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:  Icon(LucideIcons.graduationCap, color: AP.blue, size: 26),
                  ),
                  const SizedBox(width: 14),
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Private Coaching & Clinic',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kuasai teknik dinding & smash bersama pelatih FIP',
                          style: TextStyle(color: AP.slate, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CoachesScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AP.lime,
                      foregroundColor: AP.onLime,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      elevation: 0,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const ChamferBorder(br: 10, tl: 10),
                    ),
                    child: const Text('Lihat',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 12)),
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
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: sel,
                      onSelected: (val) {
                        if (val) {
                          APHaptics.light();
                          setState(() => _cat = cat);
                        }
                      },
                      selectedColor: AP.blue,
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : AP.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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

