import '../core/widgets/ap_shape.dart';
import '../core/widgets/ap_banners.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/responsive_container.dart';
import '../data.dart';
import '../core/utils/ui.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';
import 'booking_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    MatchStore.instance.refresh();
  }

  void _showCreateMatchDialog(BuildContext context) {
    if (!requireLogin(context, 'membuat match mabar')) return;
    if (courts.isEmpty) return;
    final titleCtrl = TextEditingController(text: 'Mabar Padel Doubles');
    Court selectedCourt = courts.first;
    String selectedLevel = 'Semua Level (Casual)';
    String selectedTime = '19:00 – 21:00 (2 jam)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              const Text(
                'Buat Match Mabar Baru',
                style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Judul Match Mabar',
                  hintText: 'Contoh: Mabar Santai Weekend',
                  filled: true,
                  fillColor: AP.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Court>(
                initialValue: selectedCourt,
                decoration: InputDecoration(
                  labelText: 'Pilih Lapangan',
                  filled: true,
                  fillColor: AP.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: courts.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text('${c.name} (${c.area})',
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedCourt = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: InputDecoration(
                  labelText: 'Target Level Pemain',
                  filled: true,
                  fillColor: AP.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Semua Level (Casual)',
                      child: Text('Semua Level (Casual)')),
                  DropdownMenuItem(
                      value: 'Pemula (Beginner)',
                      child: Text('Pemula (Beginner)')),
                  DropdownMenuItem(
                      value: 'Menengah (Intermediate)',
                      child: Text('Menengah (Intermediate)')),
                  DropdownMenuItem(
                      value: 'Mahir (Advanced / Pro)',
                      child: Text('Mahir (Advanced / Pro)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedLevel = val);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await MatchStore.instance.create(
                        court: selectedCourt,
                        dateString: 'Besok',
                        time: selectedTime,
                        title: titleCtrl.text.trim().isEmpty ? 'Mabar Padel' : titleCtrl.text.trim(),
                        skillLevel: selectedLevel,
                        maxPlayers: 4,
                        pricePerPlayer: (selectedCourt.pricePerHour / 2).round(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        showInfo(context,
                            'Match mabar di ${selectedCourt.name} berhasil dibuat! Menunggu pemain lain bergabung.');
                      }
                    } on ApiException catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    elevation: 0,
                    shape: ChamferBorder(br: 10, tl: 10),
                  ),
                  child: const Text('Publikasikan Match',
                      style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, fontSize: 18.4)),
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
    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: const Text(
          'Mabar & Cari Lawan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Buat Match Mabar',
            icon:  Icon(LucideIcons.plus, color: AP.blue, size: 26),
            onPressed: () => _showCreateMatchDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveContainer(
        child: AnimatedBuilder(
          animation: MatchStore.instance,
        builder: (context, _) {
          final allMatches = MatchStore.instance.matches;
          final list = allMatches.where((m) {
            if (_selectedFilter == 'Semua') return true;
            return m.skillLevel
                .toLowerCase()
                .contains(_selectedFilter.toLowerCase());
          }).toList();

          return APList(
            onRefresh: MatchStore.instance.refresh,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/court_nine_monas.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: .62), BlendMode.darken),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Main Bareng Komunitas',
                            style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                              color: Colors.white,
                              fontSize: 19.55,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kekurangan pemain? Gabung match terbuka atau buat slot mabar Anda sendiri.',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Filter Chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['Semua', 'Pemula', 'Menengah', 'Mahir'].map((lvl) {
                    final sel = _selectedFilter == lvl;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = lvl),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AP.blue : AP.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sel ? AP.blue : AP.line),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: AP.blue.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          lvl == 'Semua' ? 'Semua Level' : lvl,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AP.slate,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Match Terbuka Tersedia',
                    style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${list.length} match aktif',
                    style:  TextStyle(
                        color: AP.slate, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AP.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AP.line),
                  ),
                  child: Column(
                    children: [
                       APRacketIcon(size: 44, color: AP.slate),
                      const SizedBox(height: 10),
                      Text(
                        'Tidak ada match level "$_selectedFilter"',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'Coba pilih level lain atau buat match mabar baru!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AP.slate, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...list.map((m) => _MatchCard(match: m)),
            ],
          );
        },
      ),
    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateMatchDialog(context),
        backgroundColor: AP.blue,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Buat Mabar', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final OpenMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final c = match.court;
    final isFull = match.currentPlayers >= match.maxPlayers;
    final joined = match.isJoined;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: joined ? AP.blue : AP.line,
          width: joined ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top court bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: apImg(
c.image, fallbackUrl: c.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: c.gradient),
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
                        match.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.name} • ${c.venue}',
                        style:  TextStyle(color: AP.slate, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(court: c),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AP.cloud,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:  Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Detail',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AP.blue)),
                        Icon(LucideIcons.chevronRight, size: 14, color: AP.blue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

           Divider(color: AP.line, height: 1),

          // Match details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                     Icon(LucideIcons.calendar, size: 15, color: AP.slate),
                    const SizedBox(width: 6),
                    Text(match.dateString,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 14),
                     Icon(LucideIcons.clock, size: 15, color: AP.slate),
                    const SizedBox(width: 6),
                    Text(match.time,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AP.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match.skillLevel,
                        style:  TextStyle(
                          color: AP.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Host: ${match.hostName}',
                      style:  TextStyle(color: AP.slate, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Interactive Mini Doubles Court Schematic
                _MiniDoublesCourt(match: match),
                const SizedBox(height: 12),

                // Player slot progress & Price
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFull ? Colors.orange.shade50 : AP.blueSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFull
                            ? 'Slot Penuh (4/4)'
                            : 'Tersisa ${match.maxPlayers - match.currentPlayers} slot (${match.currentPlayers}/${match.maxPlayers})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isFull ? Colors.orange.shade800 : AP.blue,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp${match.pricePerPlayer}k',
                          style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                            fontSize: 18.4,
                            fontWeight: FontWeight.w800,
                            color: AP.blue,
                          ),
                        ),
                         Text(
                          '/ orang',
                          style: TextStyle(fontSize: 11, color: AP.slate),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: joined
                        ? OutlinedButton.icon(
                            key: const ValueKey('joined_btn'),
                            onPressed: () async {
                              APHaptics.light();
                              try {
                                await MatchStore.instance.toggleJoin(match.id);
                                if (context.mounted) showInfo(context, 'Anda keluar dari slot match ini.');
                              } on ApiException catch (e) {
                                if (context.mounted) showError(context, e);
                              }
                            },
                            icon:  Icon(LucideIcons.circleCheck,
                                color: AP.blue, size: 18),
                            label: const Text('Sudah Bergabung (Batalkan)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AP.blue,
                              side:  BorderSide(color: AP.blue),
                              shape: ChamferBorder(br: 10, tl: 10),
                            ),
                          )
                        : ElevatedButton(
                            key: const ValueKey('join_btn'),
                            onPressed: isFull
                                ? null
                                : () async {
                                    if (!requireLogin(context, 'bergabung ke match')) return;
                                    APHaptics.success();
                                    try {
                                      final ok = await MatchStore.instance.toggleJoin(match.id);
                                      if (ok && context.mounted) {
                                        showInfo(context,
                                            'Berhasil bergabung dengan match ${match.title}! Sampai jumpa di lapangan.');
                                      }
                                    } on ApiException catch (e) {
                                      if (context.mounted) showError(context, e);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AP.lime,
                              foregroundColor: AP.onLime,
                              disabledBackgroundColor: AP.line,
                              elevation: 0,
                              shape: ChamferBorder(br: 10, tl: 10),
                            ),
                            child: Text(
                              isFull ? 'Slot Penuh' : 'Gabung Slot Mabar',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDoublesCourt extends StatelessWidget {
  final OpenMatch match;

  const _MiniDoublesCourt({required this.match});

  Widget _buildSlot({
    required bool filled,
    required String label,
    required IconData icon,
    bool isHost = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: filled
                ? (isHost ? AP.lime : const Color(0xFFC7F23C))
                : Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? AP.lime : Colors.white38,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: filled ? AP.onLime : Colors.white70,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: filled ? FontWeight.w800 : FontWeight.w500,
            color: filled ? Colors.white : Colors.white60,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = match.currentPlayers;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F5A38), // Authentic padel turf green
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle court divider lines
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Players on court
          Row(
            children: [
              // Team A (Kiri)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSlot(
                      filled: true,
                      label: 'Host',
                      icon: LucideIcons.star,
                      isHost: true,
                    ),
                    _buildSlot(
                      filled: cur >= 2,
                      label: cur >= 2 ? 'Partner' : '+ Slot',
                      icon: cur >= 2 ? LucideIcons.userRound : LucideIcons.plus,
                    ),
                  ],
                ),
              ),

              // Net in the center
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: AP.surface,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),

              // Team B (Kanan)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSlot(
                      filled: cur >= 3,
                      label: cur >= 3 ? 'Lawan 1' : '+ Slot',
                      icon: cur >= 3 ? LucideIcons.userRound : LucideIcons.plus,
                    ),
                    _buildSlot(
                      filled: cur >= 4,
                      label: cur >= 4 ? 'Lawan 2' : '+ Slot',
                      icon: cur >= 4 ? LucideIcons.userRound : LucideIcons.plus,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
