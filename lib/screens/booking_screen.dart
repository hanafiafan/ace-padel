import '../core/widgets/ap_shape.dart';
import '../core/widgets/ap_banners.dart';
import 'package:flutter/material.dart';
import '../core/widgets/ap_decor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/utils/haptics.dart';
import '../core/utils/ui.dart';
import '../services/api_service.dart';
import '../core/widgets/responsive_container.dart';
import '../data.dart';
import '../store.dart';
import '../theme.dart';
import 'confirm_screen.dart';

class BookingScreen extends StatefulWidget {
  final Court court;
  const BookingScreen({super.key, required this.court});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _selectedDay;
  String? _slot;
  int _selectedDurationMinutes = 60; // 60, 90, 120 Menit
  int _selectedSpecIndex = 0; // 0: Dimensi, 1: Turf, 2: Kaca, 3: LED

  late final List<DateTime> _days;

  int get _calculatedPrice =>
      (widget.court.pricePerHour * _selectedDurationMinutes / 60).round();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = List.generate(7, (i) => today.add(Duration(days: i)));
    _selectedDay = _days.first;
    BookingStore.instance.addListener(_rebuild);
    BookingStore.instance.loadSlots(widget.court, _selectedDay);
    ReviewStore.instance.load(widget.court.id);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BookingStore.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _confirm() {
    final slot = _slot;
    if (slot == null) return;
    if (!requireLogin(context, 'memesan lapangan')) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmScreen(
          court: widget.court,
          date: _selectedDay,
          slot: slot,
          durationMinutes: _selectedDurationMinutes,
        ),
      ),
    ).then((_) => BookingStore.instance.loadSlots(widget.court, _selectedDay)); // refresh slot
  }

  void _showWriteReviewDialog() {
    if (!requireLogin(context, 'menulis ulasan')) return;
    double selectedRating = 5.0;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
              Text(
                'Beri Ulasan untuk ${widget.court.name}',
                style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  return IconButton(
                    icon: Icon(
                      starVal <= selectedRating ? LucideIcons.star : LucideIcons.star,
                      color: const Color(0xFFF5B301),
                      size: 34,
                    ),
                    onPressed: () {
                      setSheetState(() => selectedRating = starVal);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ceritakan pengalaman bermain Anda di sini...',
                  filled: true,
                  fillColor: AP.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final comment = commentCtrl.text.trim();
                    if (comment.isEmpty) return;
                    try {
                      await ReviewStore.instance.submit(widget.court.id, selectedRating, comment);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) showInfo(context, 'Terima kasih! Ulasan Anda berhasil diterbitkan.');
                    } on ApiException catch (e) {
                      if (mounted) showError(context, e);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    shape: const ChamferBorder(br: 10, tl: 10),
                  ),
                  child: const Text('Kirim Ulasan',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _facilityIcon(String text) {
    final t = text.toLowerCase();
    if (t.contains('raket')) return kRacketIcon;
    if (t.contains('bola')) return kBallIcon;
    if (t.contains('shower')) return LucideIcons.bath;
    if (t.contains('locker')) return LucideIcons.lock;
    if (t.contains('wifi')) return LucideIcons.wifi;
    if (t.contains('parkir')) return LucideIcons.car;
    if (t.contains('cafe') || t.contains('minuman')) return LucideIcons.coffee;
    return LucideIcons.circleCheck;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.court;
    return ResponsiveContainer(
      child: SportyCourtBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: c.gradient.first,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: 'Kembali',
              icon: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black45,
                child: Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: [
              AnimatedBuilder(
                animation: FavoriteStore.instance,
                builder: (context, _) {
                  final isFav = FavoriteStore.instance.isFavorite(c.id);
                  return IconButton(
                    tooltip: isFav ? 'Hapus favorit' : 'Tambah favorit',
                    icon: Icon(
                      isFav ? LucideIcons.heart : LucideIcons.heart,
                      color: isFav ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () async {
                      if (!requireLogin(context, 'menyimpan venue favorit')) return;
                      try {
                        await FavoriteStore.instance.toggle(c.id);
                      } on ApiException catch (e) {
                        if (context.mounted) showError(context, e);
                        return;
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFav
                              ? '${c.name} dihapus dari venue favorit'
                              : '${c.name} ditambahkan ke venue favorit'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                tooltip: 'Bagikan',
                icon: const Icon(LucideIcons.share2, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text:
                        'Ayo main padel di ${c.name} (${c.venue}, ${c.area}) - Mulai Rp${c.pricePerHour}k/jam. Pesan slot lewat Ace Padel: https://acepadel.app/court/${c.id}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Tautan & info ${c.name} disalin ke clipboard.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  apImg(
c.image, fallbackUrl: c.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: c.gradient),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.gradient.first.withValues(alpha: .55),
                          Colors.black.withValues(alpha: .75),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tag(c.indoor ? 'Indoor Court' : 'Outdoor Court'),
                          const SizedBox(height: 10),
                          Text(c.name,
                              style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                                  color: Colors.white,
                                  fontSize: 29.12,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin,
                                  size: 15, color: Colors.white70),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('${c.venue} • ${c.area}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70)),
                              ),
                              const SizedBox(width: 12),
                              const Icon(LucideIcons.star, size: 15, color: AP.lime),
                              const SizedBox(width: 3),
                              Text('${c.rating}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About section
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: ShapeDecoration(
                      color: AP.surface,
                      shape: const ChamferBorder(br: 18, tl: 8),
                      shadows: APShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: const ShapeDecoration(
                                color: APColors.lime,
                                shape: ChamferBorder(br: 2, tl: 2),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 3,
                              height: 16,
                              decoration: ShapeDecoration(
                                color: APColors.blue,
                                shape: const ChamferBorder(br: 2, tl: 2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TENTANG VENUE',
                              style: TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: APColors.ink,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.description,
                          style: TextStyle(
                              color: AP.slate, fontSize: 12.5, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        Divider(color: AP.line, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'FASILITAS LAPANGAN',
                              style: TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: APColors.ink,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: const ShapeDecoration(
                                color: APColors.lime,
                                shape: ChamferBorder(br: 4, tl: 2),
                              ),
                              child: const Text(
                                'READY',
                                style: TextStyle(
                                  fontFamily: 'Display',
                                  fontStyle: FontStyle.italic,
                                  color: APColors.onLime,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: c.facilities
                              .map(
                                (f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: ShapeDecoration(
                                    color: AP.cloud,
                                    shape: ChamferBorder(
                                      br: 8,
                                      tl: 4,
                                      side: BorderSide(
                                        color: APColors.blue.withValues(alpha: 0.15),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: ShapeDecoration(
                                          color: APColors.blue.withValues(alpha: 0.12),
                                          shape: const ChamferBorder(br: 4, tl: 2),
                                        ),
                                        child: APGlyph(_facilityIcon(f),
                                            size: 13, color: APColors.blue),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        f,
                                        style: TextStyle(
                                            color: APColors.ink,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Showcase Pro Rental Gear Tersedia di Venue
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4.5,
                            height: 18,
                            decoration: const ShapeDecoration(
                              color: APColors.lime,
                              shape: ChamferBorder(br: 3, tl: 3),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            width: 3.0,
                            height: 18,
                            decoration: ShapeDecoration(
                              color: APColors.blue,
                              shape: const ChamferBorder(br: 2, tl: 2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SEWA RAKET & BOLA PRO RESMI',
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              fontSize: 18.5,
                              fontWeight: FontWeight.w900,
                              color: APColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const ShapeDecoration(
                          color: APColors.lime,
                          shape: ChamferBorder(br: 4, tl: 2),
                        ),
                        child: const Text(
                          'READY DI VENUE',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            color: APColors.onLime,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 175,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: equipmentAddOns.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final item = equipmentAddOns[i];
                        return Container(
                          width: 155,
                          padding: const EdgeInsets.all(10),
                          decoration: ShapeDecoration(
                            color: AP.surface,
                            shape: ChamferBorder(
                              br: 14,
                              tl: 6,
                              side: BorderSide(
                                color: item.accentColor.withValues(alpha: 0.3),
                                width: 1.1,
                              ),
                            ),
                            shadows: [
                              BoxShadow(
                                color: item.accentColor.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: item.accentColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: item.image.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Image.asset(
                                            item.image,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: APGlyph(item.icon, size: 28, color: item.accentColor),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: APGlyph(item.icon, size: 28, color: item.accentColor),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: ShapeDecoration(
                                      color: item.accentColor,
                                      shape: const ChamferBorder(br: 3, tl: 2),
                                    ),
                                    child: Text(
                                      item.brand.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Display',
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '+Rp${item.price}k',
                                    style: TextStyle(
                                      fontFamily: 'Display',
                                      fontStyle: FontStyle.italic,
                                      color: APColors.blue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontFamily: 'Display',
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  color: APColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                item.model.isNotEmpty ? item.model : item.description,
                                style: TextStyle(color: AP.slate, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('PILIH TANGGAL',
                      style:
                          TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _days.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _dateChip(_days[i]),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text('PILIH DURASI MAIN',
                      style:
                          TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _durationPicker(),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PILIH JAM MAIN',
                          style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                              fontSize: 20.7, fontWeight: FontWeight.w800)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AP.blueSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(LucideIcons.clock, size: 12, color: AP.blue),
                            const SizedBox(width: 4),
                            Text(
                              'Durasi: $_selectedDurationMinutes Menit',
                              style:  TextStyle(
                                color: AP.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Segment 1: Pagi
                  _timeHeader('Pagi', '08:00 – 11:00'),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: allSlots.take(4).map(_slotTile).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Segment 2: Siang & Sore
                  _timeHeader('Siang & Sore', '12:00 – 17:00'),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: allSlots.skip(4).take(6).map(_slotTile).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Segment 3: Malam / Peak Hours
                  _timeHeader('Malam (Jam Favorit)', '18:00 – 21:00', isPeak: true),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.3,
                    children: allSlots.skip(10).map(_slotTile).toList(),
                  ),

                  const SizedBox(height: 24),

                  // FIP Tournament Court Specs Card
                  _fipCourtSpecsCard(),

                  const SizedBox(height: 28),

                  // Reviews section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('ULASAN PEMAIN',
                              style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                                  fontSize: 20.7, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.star,
                              color: Color(0xFFF5B301), size: 18),
                          const SizedBox(width: 3),
                          Text('${widget.court.rating}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _showWriteReviewDialog,
                        icon:  Icon(LucideIcons.messageSquareText,
                            size: 16, color: AP.blue),
                        label:  Text('Tulis Ulasan',
                            style: TextStyle(
                                color: AP.blue, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: ReviewStore.instance,
                    builder: (context, _) {
                      final reviews = ReviewStore.instance
                          .getReviewsForCourt(widget.court.id);
                      if (reviews.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AP.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AP.line),
                          ),
                          child:  Center(
                            child: Text(
                              'Belum ada ulasan untuk lapangan ini. Jadilah yang pertama memberi ulasan!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AP.slate, fontSize: 13),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: reviews.map((r) => _reviewCard(r)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
        ),
      ),
    );
  }

  Widget _reviewCard(CourtReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: AP.surface,
        shape: ChamferBorder(
          br: 16,
          tl: 6,
          side: BorderSide(
            color: APColors.blue.withValues(alpha: 0.18),
            width: 1.1,
          ),
        ),
        shadows: APShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: ShapeDecoration(
                  color: APColors.blue,
                  shape: const ChamferBorder(br: 8, tl: 4),
                  shadows: APShadows.primaryButton,
                ),
                child: Center(
                  child: Text(
                    r.userName.isNotEmpty ? r.userName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontFamily: 'Display',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.userName,
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: APColors.ink,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: const ShapeDecoration(
                            color: APColors.lime,
                            shape: ChamferBorder(br: 4, tl: 2),
                          ),
                          child: const Text(
                            'VERIFIED',
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: APColors.onLime,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.skillLevel.toUpperCase()} • ${r.date}',
                      style: TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        color: AP.slate,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: const ChamferBorder(br: 6, tl: 3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.star, color: Color(0xFFD97706), size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${r.rating}',
                      style: const TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              color: AP.cloud,
              shape: const ChamferBorder(br: 8, tl: 4),
            ),
            child: Text(
              r.comment,
              style: TextStyle(
                color: APColors.ink,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(14)),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      );

  Widget _dateChip(DateTime d) {
    final selected = d == _selectedDay;
    return GestureDetector(
      onTap: () {
        APHaptics.light();
        setState(() {
          _selectedDay = d;
          _slot = null; // reset karena ketersediaan beda per hari
        });
        BookingStore.instance.loadSlots(widget.court, d);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 60,
        decoration: ShapeDecoration(
          color: selected ? APColors.lime : AP.surface,
          shape: ChamferBorder(
            br: 16,
            tl: 6,
            side: BorderSide(
              color: selected ? APColors.lime : AP.line,
              width: selected ? 1.6 : 1.0,
            ),
          ),
          shadows: selected
              ? [
                  BoxShadow(
                    color: APColors.lime.withValues(alpha: 0.38),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : APShadows.subtle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE').format(d).toUpperCase(),
              style: TextStyle(
                fontFamily: 'Display',
                fontStyle: FontStyle.italic,
                color: selected ? APColors.onLime : AP.slate,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${d.day}',
              style: TextStyle(
                fontFamily: 'Display',
                fontStyle: FontStyle.italic,
                color: selected ? APColors.onLime : AP.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            // Reference active indicator dot below date
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected ? APColors.onLime : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeHeader(String title, String range, {bool isPeak = false}) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: const ShapeDecoration(
            color: APColors.lime,
            shape: ChamferBorder(br: 2, tl: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Display',
            fontStyle: FontStyle.italic,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: AP.ink,
            letterSpacing: 0.3,
          ),
        ),
        if (isPeak) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: const ShapeDecoration(
              color: Color(0xFFFEF3C7),
              shape: ChamferBorder(br: 4, tl: 2),
            ),
            child: const Text(
              'PEAK HOURS',
              style: TextStyle(
                fontFamily: 'Display',
                fontStyle: FontStyle.italic,
                color: Color(0xFF92400E),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          range,
          style: TextStyle(
            fontFamily: 'Display',
            fontStyle: FontStyle.italic,
            color: AP.slate,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _slotTile(String slot) {
    final taken =
        BookingStore.instance.isTaken(widget.court, _selectedDay, slot);
    final selected = slot == _slot;
    return GestureDetector(
      onTap: taken
          ? null
          : () {
              APHaptics.medium();
              setState(() => _slot = slot);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: taken
              ? AP.line.withValues(alpha: 0.5)
              : (selected ? APColors.blue : AP.surface),
          shape: ChamferBorder(
            br: 12,
            tl: 4,
            side: BorderSide(
              color: selected
                  ? APColors.lime
                  : (taken ? Colors.transparent : APColors.blue.withValues(alpha: 0.2)),
              width: selected ? 1.8 : 1.0,
            ),
          ),
          shadows: selected
              ? [
                  BoxShadow(
                    color: APColors.blue.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!taken && !selected) ...[
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              slot,
              style: TextStyle(
                fontFamily: 'Display',
                fontStyle: FontStyle.italic,
                color: taken
                    ? AP.slate
                    : (selected ? Colors.white : AP.ink),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.3,
                decoration: taken ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationPicker() {
    final durations = [60]; // server books one hourly slot per reservation
    return Row(
      children: durations.map((d) {
        final selected = _selectedDurationMinutes == d;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              APHaptics.light();
              setState(() => _selectedDurationMinutes = d);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AP.blue : AP.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AP.blue : AP.line,
                  width: selected ? 1.5 : 1.0,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AP.blue.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$d Menit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AP.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d == 60 ? 'Standar' : (d == 90 ? '1.5 Jam' : '2 Jam Penuh'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white70 : AP.slate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _fipCourtSpecsCard() {
    final specDetails = [
      {
        'title': 'Dimensi Resmi FIP',
        'badge': 'REGULASI TURNAMEN',
        'desc': 'Panjang 20 meter, lebar 10 meter untuk nomor ganda doubles. Tinggi net 88 cm di tengah dan 92 cm di kedua sisi tiang sesuai ketetapan Federasi Padel Internasional.',
        'icon': LucideIcons.ruler,
      },
      {
        'title': 'Mondo Supercourt XN Turf',
        'badge': 'OFFICIAL WPT GRADE',
        'desc': 'Rumput sintetis monofilament generasi terbaru dengan daya serap kejut 60%. Memberikan pantulan bola 100% konsisten tanpa pasir terlihat di permukaan.',
        'icon': LucideIcons.sprout,
      },
      {
        'title': '12mm Tempered Safety Glass',
        'badge': 'SAFETY STANDARD CE',
        'desc': 'Dinding kaca tempered 12mm anti-pecah dengan transmisi optik tinggi. Memberikan pantulan dinding yang presisi dan aman dari benturan keras pemain.',
        'icon': LucideIcons.shield,
      },
      {
        'title': 'LED Linear 550+ Lux Anti-Silau',
        'badge': 'COMPETITION LIGHTING',
        'desc': '8 unit lampu LED linear 200W tanpa silau (no-glare) yang menerangi seluruh area baseline dan sudut kaca secara merata untuk match malam hari.',
        'icon': LucideIcons.lightbulb,
      },
    ];

    final current = specDetails[_selectedSpecIndex];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: AP.surface,
        shape: const ChamferBorder(br: 18, tl: 8),
        shadows: APShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const ShapeDecoration(
                  color: APColors.lime,
                  shape: ChamferBorder(br: 6, tl: 3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.badgeCheck, size: 13, color: APColors.onLime),
                    SizedBox(width: 4),
                    Text(
                      'STANDAR FIP INTERNASIONAL',
                      style: TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        color: APColors.onLime,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: ShapeDecoration(
                  color: APColors.blue.withValues(alpha: 0.12),
                  shape: const ChamferBorder(br: 6, tl: 3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: APColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'INSPEKSI GRADE A',
                      style: TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        color: APColors.blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: const ShapeDecoration(
                  color: APColors.lime,
                  shape: ChamferBorder(br: 2, tl: 2),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 3,
                height: 16,
                decoration: ShapeDecoration(
                  color: APColors.blue,
                  shape: const ChamferBorder(br: 2, tl: 2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'VISUALISASI SPESIFIKASI LAPANGAN',
                style: TextStyle(
                  fontFamily: 'Display',
                  fontStyle: FontStyle.italic,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: APColors.ink,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // High-Octane Stadium Arena Visualizer Canvas
          Container(
            height: 135,
            width: double.infinity,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF070C20), Color(0xFF041A12)],
              ),
              shape: ChamferBorder(
                br: 16,
                tl: 8,
                side: BorderSide(
                  color: _selectedSpecIndex == 2
                      ? APColors.lime
                      : const Color(0xFF132B25),
                  width: _selectedSpecIndex == 2 ? 2.0 : 1.2,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Tournament Turf Floor
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F5A38),
                            _selectedSpecIndex == 1
                                ? const Color(0xFF00A86B)
                                : const Color(0xFF083C25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedSpecIndex == 0
                              ? APColors.lime
                              : Colors.white.withValues(alpha: 0.5),
                          width: _selectedSpecIndex == 0 ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Court boundary lines & service boxes
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                              // Net line
                              Container(
                                width: 3,
                                color: Colors.white,
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Corner Lighting Spot Beams
                if (_selectedSpecIndex == 3) ...[
                  for (final pos in [
                    const Alignment(-0.92, -0.85),
                    const Alignment(0.92, -0.85),
                    const Alignment(-0.92, 0.85),
                    const Alignment(0.92, 0.85),
                    const Alignment(-0.30, -0.92),
                    const Alignment(0.30, -0.92),
                    const Alignment(-0.30, 0.92),
                    const Alignment(0.30, 0.92),
                  ])
                    Align(
                      alignment: pos,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: APColors.lime,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: APColors.lime,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                // Center court callout overlay badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: const ShapeDecoration(
                      color: Color(0xEE060A18),
                      shape: ChamferBorder(
                        br: 8,
                        tl: 4,
                        side: BorderSide(color: APColors.lime, width: 1.2),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.activity, size: 12, color: APColors.lime),
                        const SizedBox(width: 5),
                        Text(
                          current['title'] as String,
                          style: const TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            color: APColors.lime,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Interactive Spec Selection Tabs (Chamfered sporty tabs)
          Row(
            children: [
              _specTab(0, LucideIcons.ruler, 'Dimensi'),
              const SizedBox(width: 6),
              _specTab(1, LucideIcons.sprout, 'Turf'),
              const SizedBox(width: 6),
              _specTab(2, LucideIcons.shield, 'Kaca 12mm'),
              const SizedBox(width: 6),
              _specTab(3, LucideIcons.lightbulb, 'LED Lux'),
            ],
          ),

          const SizedBox(height: 12),

          // Description Card for selected spec - Using Wrap to PREVENT ANY OVERFLOW BUG!
          Container(
            padding: const EdgeInsets.all(14),
            decoration: ShapeDecoration(
              color: AP.cloud,
              shape: ChamferBorder(
                br: 12,
                tl: 6,
                side: BorderSide(
                  color: APColors.blue.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: ShapeDecoration(
                    color: APColors.blue,
                    shape: const ChamferBorder(br: 8, tl: 4),
                    shadows: APShadows.primaryButton,
                  ),
                  child: Icon(current['icon'] as IconData, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            current['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Display',
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: APColors.ink,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: const ShapeDecoration(
                              color: APColors.lime,
                              shape: ChamferBorder(br: 4, tl: 2),
                            ),
                            child: Text(
                              current['badge'] as String,
                              style: const TextStyle(
                                fontFamily: 'Display',
                                fontStyle: FontStyle.italic,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: APColors.onLime,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current['desc'] as String,
                        style: TextStyle(
                          color: AP.slate,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specTab(int index, IconData icon, String label) {
    final sel = _selectedSpecIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          APHaptics.light();
          setState(() => _selectedSpecIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShapeDecoration(
            color: sel ? APColors.blue : AP.surface,
            shape: ChamferBorder(
              br: 10,
              tl: 4,
              side: BorderSide(
                color: sel ? APColors.blue : AP.line,
                width: sel ? 1.5 : 1,
              ),
            ),
            shadows: sel ? APShadows.primaryButton : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: sel ? Colors.white : AP.ink),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Display',
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w900 : FontWeight.w700,
                  color: sel ? Colors.white : AP.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final ready = _slot != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const ShapeDecoration(
        color: Color(0xFF070B1F),
        shape: ChamferBorder(
          br: 14,
          tl: 14,
          side: BorderSide(color: Color(0xFF1B2B50), width: 1.2),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL // $_selectedDurationMinutes MIN',
                style: const TextStyle(
                  fontFamily: 'Display',
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF8A99AD),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Rp${_calculatedPrice}k',
                    style: const TextStyle(
                      fontFamily: 'Display',
                      fontStyle: FontStyle.italic,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: APColors.lime,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ MATCH',
                    style: TextStyle(
                      fontFamily: 'Display',
                      fontStyle: FontStyle.italic,
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: ready
                    ? ElevatedButton.icon(
                        key: const ValueKey('ready_btn'),
                        onPressed: _confirm,
                        icon: const Icon(LucideIcons.arrowRight, size: 18),
                        label: const Text(
                          'LANJUT KONFIRMASI',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: APColors.lime,
                          foregroundColor: APColors.onLime,
                          elevation: 4,
                          shadowColor: APColors.lime.withValues(alpha: 0.4),
                          minimumSize: const Size.fromHeight(52),
                          shape: const ChamferBorder(br: 12, tl: 6),
                        ),
                      )
                    : ElevatedButton.icon(
                        key: const ValueKey('not_ready_btn'),
                        onPressed: null,
                        icon: const Icon(LucideIcons.clock, size: 16),
                        label: const Text(
                          'PILIH JAM MAIN',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: const Color(0xFF141C33),
                          disabledForegroundColor: const Color(0xFF5A6882),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(52),
                          shape: const ChamferBorder(br: 12, tl: 6),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
