import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import 'package:intl/intl.dart';
import '../core/widgets/responsive_container.dart';
import '../data.dart';
import '../theme.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  String _selectedFilter = 'Semua';
  String _query = '';
  final _searchCtrl = TextEditingController();

  final List<String> _filters = const [
    'Semua',
    'Bandeja & Vibora',
    'Pemula & Wanita',
    'Wall Defense',
    'Taktik Double',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Coach> get _filteredCoaches {
    return initialCoaches.where((c) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final match = c.name.toLowerCase().contains(q) ||
            c.title.toLowerCase().contains(q) ||
            c.specialties.any((s) => s.toLowerCase().contains(q));
        if (!match) return false;
      }
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Bandeja & Vibora') {
        return c.specialties.any((s) => s.toLowerCase().contains('vibora') || s.toLowerCase().contains('bandeja'));
      }
      if (_selectedFilter == 'Pemula & Wanita') {
        return c.specialties.any((s) => s.toLowerCase().contains('pemula')) || c.title.toLowerCase().contains('women');
      }
      if (_selectedFilter == 'Wall Defense') {
        return c.specialties.any((s) => s.toLowerCase().contains('wall')) || c.bio.toLowerCase().contains('kaca');
      }
      if (_selectedFilter == 'Taktik Double') {
        return c.specialties.any((s) => s.toLowerCase().contains('double') || s.toLowerCase().contains('taktik'));
      }
      return true;
    }).toList();
  }

  void _bookCoachSession(Coach coach) {
    String selectedVenue = coach.availableVenues.first;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '16:00';
    String selectedFocus = coach.specialties.first;

    final availableSlots = ['09:00', '10:00', '14:00', '16:00', '18:00', '20:00'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
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
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AP.blue,
                    backgroundImage: coach.image.isNotEmpty ? AssetImage(coach.image) : null,
                    child: coach.image.isEmpty
                        ? Text(
                            coach.name.split(' ').map((e) => e[0]).take(2).join(),
                            style: const TextStyle(fontFamily: 'Display', 
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18.4,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Private Coaching: ${coach.name}',
                          style: const TextStyle(fontFamily: 'Display', 
                              fontSize: 18.4, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          coach.title,
                          style:  TextStyle(color: AP.slate, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
               Divider(color: AP.line, height: 1),
              const SizedBox(height: 14),

              // Pilih Venue
              const Text(
                'Pilih Lokasi Venue:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: coach.availableVenues.map((venue) {
                  final isSelected = selectedVenue == venue;
                  return ChoiceChip(
                    label: Text(venue),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setModalState(() => selectedVenue = venue);
                    },
                    selectedColor: AP.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AP.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    backgroundColor: AP.cloud,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AP.blue : AP.line,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Pilih Jam Sesi
              const Text(
                'Pilih Jam Sesi Coaching (1 Jam):',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: availableSlots.map((slot) {
                  final isSelected = selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setModalState(() => selectedSlot = slot);
                    },
                    selectedColor: AP.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AP.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    backgroundColor: AP.cloud,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AP.blue : AP.line,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Fokus Materi
              const Text(
                'Fokus Materi Latihan:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AP.cloud,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AP.line),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedFocus,
                    isExpanded: true,
                    items: coach.specialties.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedFocus = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Total Harga
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AP.cloud,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Biaya Coaching (1 Jam)',
                            style: TextStyle(color: AP.slate, fontSize: 12)),
                        Text('Termasuk lapangan & bola',
                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(
                      'Rp${coach.ratePerHour}k',
                      style:  TextStyle(fontFamily: 'Display', 
                        fontSize: 20.7,
                        fontWeight: FontWeight.w800,
                        color: AP.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Button Konfirmasi
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sesi coaching bersama ${coach.name} pada ${DateFormat('EEE, d MMM').format(selectedDate)} pukul $selectedSlot WIB berhasil dijadwalkan!',
                        ),
                        backgroundColor: AP.blueDark,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Konfirmasi Jadwal Coaching',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
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
    final list = _filteredCoaches;

    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: const Text(
          'Pelatih & Coaching Padel',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ResponsiveContainer(
        child: APList(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Banner Highlight Coaching
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/court_nine_monas.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: .62), BlendMode.darken),
              ),
              gradient:  LinearGradient(
                colors: [AP.blueDark, AP.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AP.lime,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:  Text(
                        'OFFICIAL COACHING',
                        style: TextStyle(
                          color: AP.onLime,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(LucideIcons.badgeCheck, color: AP.lime, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tingkatkan Level Permainan Anda',
                  style: TextStyle(fontFamily: 'Display', 
                    color: Colors.white,
                    fontSize: 20.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kuasai teknik pantulan kaca, smash vibora, dan taktik turnamen bersama pelatih berlisensi internasional.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AP.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AP.line),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari nama pelatih atau spesialisasi...',
                hintStyle:  TextStyle(color: AP.slate, fontSize: 13),
                icon:  Icon(LucideIcons.search, color: AP.slate, size: 20),
                border: InputBorder.none,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon:  Icon(LucideIcons.x, color: AP.slate, size: 18),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = '';
                        }),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Specialty Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final isSelected = _selectedFilter == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = f);
                  },
                  selectedColor: AP.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AP.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  backgroundColor: AP.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? AP.blue : AP.line,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Count
          Text(
            '${list.length} Pelatih Tersedia',
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AP.slate,
            ),
          ),
          const SizedBox(height: 12),

          // List of Coach Cards
          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AP.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AP.line),
              ),
              child:  Column(
                children: [
                  Icon(LucideIcons.search, size: 48, color: AP.slate),
                  SizedBox(height: 10),
                  Text(
                    'Tidak ada pelatih yang cocok',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Coba gunakan kata kunci atau filter lain.',
                    style: TextStyle(color: AP.slate, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...list.map((c) => _CoachCard(coach: c, onBook: () => _bookCoachSession(c))),
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final Coach coach;
  final VoidCallback onBook;

  const _CoachCard({required this.coach, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AP.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AP.blue,
                backgroundImage: coach.image.isNotEmpty ? AssetImage(coach.image) : null,
                child: coach.image.isEmpty
                    ? Text(
                        coach.name.split(' ').map((e) => e[0]).take(2).join(),
                        style: const TextStyle(fontFamily: 'Display', 
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20.7,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            coach.name,
                            style: const TextStyle(fontFamily: 'Display', 
                              fontSize: 18.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                         Icon(LucideIcons.badgeCheck, color: AP.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coach.title,
                      style:  TextStyle(
                        color: AP.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.star,
                            color: Color(0xFFFFAE00), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '${coach.rating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          ' (${coach.reviewsCount})',
                          style:  TextStyle(color: AP.slate, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '• ${coach.experience}',
                            style:
                                 TextStyle(color: AP.slate, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            coach.bio,
            style:  TextStyle(color: AP.ink, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),

          // Specialties chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: coach.specialties.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AP.lime.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s,
                  style:  TextStyle(
                    color: AP.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
           Divider(color: AP.line, height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Tarif per jam',
                      style: TextStyle(color: AP.slate, fontSize: 11)),
                  Text(
                    'Rp${coach.ratePerHour}k',
                    style:  TextStyle(fontFamily: 'Display', 
                      fontSize: 19.55,
                      fontWeight: FontWeight.w800,
                      color: AP.blue,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: onBook,
                icon: const Icon(LucideIcons.calendarDays, size: 16),
                label: const Text(
                  'Book Sesi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AP.lime,
                  foregroundColor: AP.onLime,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
