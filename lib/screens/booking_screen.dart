import 'package:flutter/material.dart';
import '../core/widgets/ap_decor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/utils/haptics.dart';
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
  }

  void _confirm() {
    final slot = _slot;
    if (slot == null) return;
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
    ).then((_) => setState(() {})); // refresh slot jika status berubah
  }

  void _showWriteReviewDialog() {
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
                style: const TextStyle(fontFamily: 'Display', fontSize: 20.7, fontWeight: FontWeight.w800),
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
                  onPressed: () {
                    final comment = commentCtrl.text.trim();
                    if (comment.isEmpty) return;
                    final user = UserStore.instance.profile;
                    ReviewStore.instance.addReview(
                      CourtReview(
                        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
                        courtId: widget.court.id,
                        userName: user.name,
                        rating: selectedRating,
                        comment: comment,
                        date: 'Hari ini',
                        skillLevel: user.skillLevel.split(' ').first,
                      ),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Terima kasih! Ulasan Anda berhasil diterbitkan.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
      child: Scaffold(
        backgroundColor: AP.cloud,
        body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: c.gradient.first,
            foregroundColor: Colors.white,
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
                    onPressed: () {
                      FavoriteStore.instance.toggle(c.id);
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
                  Image.asset(
                    c.image,
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
                              style: const TextStyle(fontFamily: 'Display', 
                                  color: Colors.white,
                                  fontSize: 29.12,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin,
                                  size: 15, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text('${c.venue} • ${c.area}',
                                  style: const TextStyle(color: Colors.white70)),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AP.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AP.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tentang Venue',
                          style: TextStyle(fontFamily: 'Display', 
                              fontSize: 18.4, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.description,
                          style:  TextStyle(
                              color: AP.slate, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                         Divider(color: AP.line, height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'Fasilitas Tersedia',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
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
                                  decoration: BoxDecoration(
                                    color: AP.cloud,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AP.line),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      APGlyph(_facilityIcon(f),
                                          size: 14, color: AP.blue),
                                      const SizedBox(width: 6),
                                      Text(
                                        f,
                                        style:  TextStyle(
                                            color: AP.ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
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

                  const Text('Pilih tanggal',
                      style:
                          TextStyle(fontFamily: 'Display', fontSize: 20.7, fontWeight: FontWeight.w800)),
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

                  const Text('Pilih Durasi Main',
                      style:
                          TextStyle(fontFamily: 'Display', fontSize: 20.7, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _durationPicker(),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pilih Jam Main',
                          style: TextStyle(fontFamily: 'Display', 
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
                          const Text('Ulasan Pemain',
                              style: TextStyle(fontFamily: 'Display', 
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
    );
  }

  Widget _reviewCard(CourtReview r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AP.blue.withValues(alpha: 0.1),
                child: Text(
                  r.userName.isNotEmpty ? r.userName[0].toUpperCase() : 'P',
                  style:  TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AP.blue,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${r.skillLevel} • ${r.date}',
                        style:  TextStyle(color: AP.slate, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(LucideIcons.star, color: Color(0xFFF5B301), size: 14),
                  const SizedBox(width: 2),
                  Text('${r.rating}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.comment,
              style:  TextStyle(color: AP.ink, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _tag(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(20)),
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
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 58,
        decoration: BoxDecoration(
          color: selected ? AP.blue : AP.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AP.blue : AP.line,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AP.blue.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('E').format(d),
                style: TextStyle(
                    color: selected ? Colors.white70 : AP.slate,
                    fontSize: 12)),
            const SizedBox(height: 4),
            Text('${d.day}',
                style: TextStyle(fontFamily: 'Display', 
                    color: selected ? Colors.white : AP.ink,
                    fontSize: 20.7,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _timeHeader(String title, String range, {bool isPeak = false}) {
    return Row(
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AP.ink,
          ),
        ),
        if (isPeak) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Populer',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          range,
          style:  TextStyle(
            color: AP.slate,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _slotTile(String slot) {
    final taken =
        BookingStore.instance.isTaken(widget.court, _selectedDay, slot);
    final selected = slot == _slot;
    Color bg;
    Color fg;
    if (taken) {
      bg = AP.line;
      fg = AP.slate;
    } else if (selected) {
      bg = AP.blue;
      fg = Colors.white;
    } else {
      bg = AP.surface;
      fg = AP.ink;
    }
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AP.blue : (taken ? Colors.transparent : AP.line),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AP.blue.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(slot,
            style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                decoration:
                    taken ? TextDecoration.lineThrough : TextDecoration.none)),
      ),
    );
  }

  Widget _durationPicker() {
    final durations = [60, 90, 120];
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
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AP.line),
        boxShadow: APShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AP.lime,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.badgeCheck, size: 13, color: AP.onLime),
                    SizedBox(width: 4),
                    Text(
                      'STANDAR FIP INTERNASIONAL',
                      style: TextStyle(
                        color: AP.onLime,
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
                decoration: BoxDecoration(
                  color: AP.blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child:  Text(
                  'Inspeksi FIP Grade A',
                  style: TextStyle(
                    color: AP.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Visualisasi Spesifikasi Lapangan',
            style: TextStyle(fontFamily: 'Display', fontSize: 18.4, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          // Interactive Court Visualizer Canvas
          Container(
            height: 125,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F5A38), // Turf
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedSpecIndex == 2 ? AP.lime : Colors.white30,
                width: _selectedSpecIndex == 2 ? 2.5 : 1.5,
              ),
              boxShadow: _selectedSpecIndex == 2
                  ? [
                      BoxShadow(
                        color: AP.lime.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Top-down court lines
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedSpecIndex == 0 ? AP.lime : Colors.white30,
                            width: _selectedSpecIndex == 0 ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            height: 1,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    // Net in center
                    Container(
                      width: 4,
                      color: AP.surface,
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _selectedSpecIndex == 0 ? AP.lime : Colors.white30,
                            width: _selectedSpecIndex == 0 ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            height: 1,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Corner Lighting Pins
                if (_selectedSpecIndex == 3) ...[
                  for (final pos in [
                    const Alignment(-0.95, -0.9),
                    const Alignment(0.95, -0.9),
                    const Alignment(-0.95, 0.9),
                    const Alignment(0.95, 0.9),
                  ])
                    Align(
                      alignment: pos,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber,
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                // Center court callout overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AP.lime),
                    ),
                    child: Text(
                      current['title'] as String,
                      style: const TextStyle(
                        color: AP.lime,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Interactive Spec Selection Tabs
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

          // Description Card for selected spec
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AP.cloud,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AP.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AP.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(current['icon'] as IconData, size: 18, color: AP.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            current['title'] as String,
                            style:  TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AP.ink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AP.lime,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              current['badge'] as String,
                              style:  TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AP.onLime,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        current['desc'] as String,
                        style:  TextStyle(
                          color: AP.slate,
                          fontSize: 11,
                          height: 1.4,
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
          decoration: BoxDecoration(
            color: sel ? AP.blue : AP.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? AP.blue : AP.line,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: AP.blue.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: sel ? Colors.white : AP.ink),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration:  BoxDecoration(
        color: AP.surface,
        border: Border(top: BorderSide(color: AP.line)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total ($_selectedDurationMinutes Menit)',
                  style:  TextStyle(color: AP.slate, fontSize: 12)),
              Text('Rp${_calculatedPrice}k',
                  style: const TextStyle(fontFamily: 'Display', 
                      fontSize: 22.4, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 54,
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
                        icon: const Icon(LucideIcons.arrowRight, size: 20),
                        label: const Text('Lanjut ke Konfirmasi',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AP.lime,
                          foregroundColor: AP.onLime,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      )
                    : ElevatedButton.icon(
                        key: const ValueKey('not_ready_btn'),
                        onPressed: null,
                        icon: const Icon(LucideIcons.clock, size: 18),
                        label: const Text('Pilih jam dulu',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: AP.line,
                          disabledForegroundColor: AP.slate,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
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
