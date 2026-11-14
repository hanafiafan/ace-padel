import '../core/widgets/ap_shape.dart';
import 'package:flutter/material.dart';
import '../core/utils/haptics.dart';
import 'settings_screen.dart';
import 'match_story_share_screen.dart';
import '../core/widgets/ap_banners.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../core/widgets/responsive_container.dart';
import '../core/utils/ui.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';
import 'achievements_screen.dart';
import 'favorites_screen.dart';
import 'payment_methods_screen.dart';
import 'notifications_screen.dart';
import 'help_screen.dart';
import 'venue_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Tanggal (hari saja) dengan sesi main, 28 hari terakhir.
  Set<DateTime> _playedDays() {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 28));
    return {
      for (final b in BookingStore.instance.bookings)
        if (b.status == 'Terkonfirmasi' || b.status == 'Check-in Selesai')
          if (!b.date.isBefore(cutoff)) DateTime(b.date.year, b.date.month, b.date.day)
    };
  }

  void _showEditProfile(BuildContext context) {
    if (!requireLogin(context, 'mengubah profil')) return;
    final user = UserStore.instance.profile;
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    String selectedLevel = user.skillLevel;

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
                'UBAH DATA PROFIL',
                style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  filled: true,
                  fillColor: AP.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  filled: true,
                  fillColor: AP.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
               Text(
                'Tingkat Keahlian Padel',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AP.slate),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AP.cloud,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
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
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await UserStore.instance.updateProfile(
                        name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                        skillLevel: selectedLevel,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) showInfo(context, 'Profil berhasil diperbarui.');
                    } on ApiException catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.lime,
                    foregroundColor: AP.onLime,
                    elevation: 0,
                    shape: const ChamferBorder(br: 10, tl: 10),
                  ),
                  child: const Text('Simpan Perubahan',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AP.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'KELUAR DARI AKUN?',
          style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, fontSize: 20.7),
        ),
        content:  Text(
          'Apakah Anda yakin ingin keluar dari sesi aplikasi Ace Padel?',
          style: TextStyle(color: AP.slate, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:  Text('Batal',
                style: TextStyle(color: AP.slate, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              UserStore.instance.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesi akun berhasil dikeluarkan.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const ChamferBorder(br: 10, tl: 10),
            ),
            child: const Text('Ya, Keluar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: SafeArea(
        child: APList(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('PROFIL SAYA',
              style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 24.64, fontWeight: FontWeight.w800)).reveal(),
          const SizedBox(height: 16),

          // User Card
          AnimatedBuilder(
            animation: UserStore.instance,
            builder: (context, _) {
              final user = UserStore.instance.profile;
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(children: [
                  const Positioned.fill(
                    child: APPhoto(asset: 'assets/images/court_nine_monas.jpg', scrim: .82),
                  ),
                  Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                     CircleAvatar(
                      radius: 32,
                      backgroundColor: AP.lime,
                      backgroundImage: (user.photoUrl ?? '').isNotEmpty ? NetworkImage(user.photoUrl!) : null,
                      child: (user.photoUrl ?? '').isNotEmpty ? null : const Icon(LucideIcons.userRound, color: AP.onLime, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                              color: Colors.white,
                              fontSize: 22.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.isLoggedIn ? user.email : 'Mode tamu - masuk untuk fitur lengkap',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.skillLevel,
                              style: const TextStyle(
                                color: AP.lime,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ubah Profil',
                      icon: const Icon(LucideIcons.pencil, color: Colors.white),
                      onPressed: () => _showEditProfile(context),
                    ),
                  ],
                ),
                  ),
                ]),
              );
            },
          ),

          // YOUR MOMENTUM & ACTIVITY GRID (Inspired by Reference 4)
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(18),
            decoration: const ShapeDecoration(
              color: Color(0xFF070B1F),
              shape: ChamferBorder(
                br: 20,
                tl: 8,
                side: BorderSide(color: Color(0xFF1B2B50), width: 1.2),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.flame, color: Color(0xFFFF6B00), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'YOUR MOMENTUM',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    ListenableBuilder(
                      listenable: BookingStore.instance,
                      builder: (_, __) => Text(
                        '${_playedDays().length}',
                        style: const TextStyle(
                          fontFamily: 'Display',
                          fontStyle: FontStyle.italic,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: APColors.lime,
                          height: 0.9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'HARI MAIN // 28 HARI TERAKHIR',
                        style: TextStyle(
                          fontFamily: 'Display',
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 7x5 Activity Grid Dot Matrix
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ACTIVITY LOG',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'M  T  W  T  F  S  S',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 4 minggu x 7 hari, Senin-Minggu; menyala = ada sesi main
                    ListenableBuilder(
                      listenable: BookingStore.instance,
                      builder: (_, __) {
                        final played = _playedDays();
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final start = today.add(Duration(days: 7 - today.weekday - 27));
                        return Column(
                          children: [
                            for (int row = 0; row < 4; row++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    for (int col = 0; col < 7; col++)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: ShapeDecoration(
                                            color: played.contains(start.add(Duration(days: row * 7 + col)))
                                                ? APColors.lime
                                                : const Color(0xFF1E2842),
                                            shape: const ChamferBorder(br: 3, tl: 1),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Story share action button
                GestureDetector(
                  onTap: () {
                    APHaptics.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MatchStoryShareScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: const ShapeDecoration(
                      color: APColors.lime,
                      shape: ChamferBorder(br: 8, tl: 4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.sparkles, size: 14, color: APColors.onLime),
                        SizedBox(width: 6),
                        Text(
                          'BUAT RECAP STORY (STRAVA-STYLE) →',
                          style: TextStyle(
                            fontFamily: 'Display',
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: APColors.onLime,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // High-Octane Metric Cards (Inspired by Reference 3 & 4)
          AnimatedBuilder(
            animation: Listenable.merge([StatsStore.instance, BookingStore.instance]),
            builder: (_, __) {
              final st = StatsStore.instance;
              return Row(
                children: [
                  _statCard(
                    icon: LucideIcons.flame,
                    iconColor: const Color(0xFFFF6B00),
                    value: '${st.hoursPlayed * 500}',
                    unit: 'KCAL',
                    label: 'EST. KALORI',
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    icon: LucideIcons.clock,
                    iconColor: APColors.blue,
                    value: '${st.hoursPlayed}',
                    unit: 'JAM',
                    label: 'MATCH TIME',
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    icon: LucideIcons.trophy,
                    iconColor: APColors.lime,
                    value: st.rank > 0 ? '#${st.rank}' : '-',
                    unit: 'DUPR',
                    label: 'RANKING',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Achievements section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PENCAPAIAN',
                  style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, fontSize: 20.7, fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AchievementsScreen()),
                ),
                child:  Text('Lihat semua',
                    style: TextStyle(
                        color: AP.blue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: AnimatedBuilder(
              animation: StatsStore.instance,
              builder: (_, __) {
                final list = StatsStore.instance.achievementList;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => AchievementBadge(a: list[i]),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Mitra Lapangan Portal Card (only for server-confirmed owner/admin)
          AnimatedBuilder(
            animation: UserStore.instance,
            builder: (context, _) => UserStore.instance.isVenueOwner
                ? _partnerCard(context)
                : const SizedBox.shrink(),
          ),

          // Navigation list
          _tile(
            LucideIcons.creditCard,
            'Metode pembayaran',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PaymentMethodsScreen(),
              ),
            ),
          ),
          _tile(
            LucideIcons.heart,
            'Venue favorit',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FavoritesScreen(),
              ),
            ),
          ),
          _tile(
            LucideIcons.bell,
            'Notifikasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
          ),
          _tile(
            LucideIcons.settings,
            'Pengaturan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          _tile(
            LucideIcons.circleHelp,
            'Bantuan & FAQ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HelpScreen(),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: UserStore.instance,
            builder: (context, _) => UserStore.instance.isLoggedIn
                ? _tile(LucideIcons.logOut, 'Keluar', danger: true, onTap: () => _showLogoutDialog(context))
                : _tile(LucideIcons.logIn, 'Masuk / Daftar', onTap: () => requireLogin(context, 'mengakses akun Anda')),
          ),
        ],
      ),
    ),
  );
}

  Widget _partnerCard(BuildContext context) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VenueDashboardScreen(),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient:  LinearGradient(
                  colors: [AP.blueDark, AP.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AP.blue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.store, color: AP.lime, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Portal Mitra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AP.lime,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child:  const Text(
                                'PARTNER',
                                style: TextStyle(
                                  color: AP.onLime,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Check-in QR tiket & kelola jadwal slot',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VenueDashboardScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AP.lime,
                      foregroundColor: AP.onLime,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: const ChamferBorder(br: 10, tl: 10),
                    ),
                    child: const Text(
                      'Buka',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: ShapeDecoration(
            color: AP.surface,
            shape: const ChamferBorder(br: 14, tl: 6),
            shadows: APShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: ShapeDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: const ChamferBorder(br: 6, tl: 3),
                    ),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AP.cloud,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        fontSize: 8.5,
                        color: APColors.slate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: TextStyle(
                    fontFamily: 'Display',
                    fontStyle: FontStyle.italic,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: APColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Display',
                  fontStyle: FontStyle.italic,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: APColors.slate,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  Widget _tile(IconData icon, String label,
          {bool danger = false, VoidCallback? onTap}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AP.surface,
          shape: const ChamferBorder(br: 14, tl: 6),
          child: InkWell(
            customBorder: const ChamferBorder(br: 14, tl: 6),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: ShapeDecoration(
                shape: ChamferBorder(
                  br: 14,
                  tl: 6,
                  side: BorderSide(
                    color: danger ? Colors.red.withValues(alpha: 0.3) : AP.line,
                    width: 1.1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: ShapeDecoration(
                      color: (danger ? Colors.red : APColors.blue).withValues(alpha: 0.1),
                      shape: const ChamferBorder(br: 6, tl: 3),
                    ),
                    child: Icon(icon, color: danger ? Colors.red : APColors.blue, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Display',
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: danger ? Colors.red : AP.ink,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: AP.slate, size: 18),
                ],
              ),
            ),
          ),
        ),
      );
}
