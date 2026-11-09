import '../core/widgets/ap_shape.dart';
import 'package:flutter/material.dart';
import 'settings_screen.dart';
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
                    shape: ChamferBorder(br: 10, tl: 10),
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
              shape: ChamferBorder(br: 10, tl: 10),
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
                      child: (user.photoUrl ?? '').isNotEmpty ? null : Icon(LucideIcons.userRound, color: AP.onLime, size: 36),
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

          // Level progress bar
          Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AP.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AP.line),
              boxShadow: APShadows.subtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(LucideIcons.medal, color: Color(0xFFF59E0B), size: 18),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Padel Skill: 3.4 / 5.0',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: APColors.blueSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:  Text(
                        'Silver Pro',
                        style: TextStyle(
                          color: APColors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child:  LinearProgressIndicator(
                    value: 0.68,
                    minHeight: 8,
                    backgroundColor: AP.line,
                    valueColor: AlwaysStoppedAnimation<Color>(APColors.blue),
                  ),
                ),
                const SizedBox(height: 8),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Menengah (Intermediate)', style: TextStyle(color: AP.slate, fontSize: 11)),
                    Text('80 XP menuju Mahir', style: TextStyle(color: AP.blue, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats row (GET /me/stats)
          AnimatedBuilder(
            animation: Listenable.merge([StatsStore.instance, BookingStore.instance]),
            builder: (_, __) {
              final st = StatsStore.instance;
              return Row(
                children: [
                  _stat('${BookingStore.instance.bookings.length}', 'Booking Aktif'),
                  const SizedBox(width: 12),
                  _stat('${st.hoursPlayed}', 'Jam Main'),
                  const SizedBox(width: 12),
                  _stat(st.rank > 0 ? '#${st.rank}' : '-', 'Peringkat'),
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
                              child:  Text(
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
                      shape: ChamferBorder(br: 10, tl: 10),
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

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AP.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AP.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style:  TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                      fontSize: 22.4,
                      fontWeight: FontWeight.w800,
                      color: AP.blue),
                ),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style:  TextStyle(color: AP.slate, fontSize: 12)),
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
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:  BorderSide(color: AP.line),
            ),
            leading: Icon(icon, color: danger ? Colors.red : AP.blue),
            title: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: danger ? Colors.red : AP.ink)),
            trailing:  Icon(LucideIcons.chevronRight, color: AP.slate),
            onTap: onTap,
          ),
        ),
      );
}
