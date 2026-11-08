import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/responsive_container.dart';
import '../core/widgets/ap_decor.dart';
import '../core/widgets/ap_banners.dart';
import '../store.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '198282293168-htj5sahbdq8oi1a49sm76jficu6s26fh.apps.googleusercontent.com',
  );

  Future<void> _handleGoogleSignIn() async {
    APHaptics.medium();
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        APHaptics.success();
        final auth = await account.authentication;
        await UserStore.instance.loginWithGoogleAccount(
          name: account.displayName ?? account.email.split('@').first,
          email: account.email,
          photoUrl: account.photoUrl,
          googleId: account.id,
          idToken: auth.idToken,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selamat datang, ${account.displayName ?? account.email}!'),
              backgroundColor: AP.blueDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('Google Sign-In Exception: $error');
      if (mounted) {
        _showGoogleConfigModal(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showGoogleConfigModal(String errorDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.info, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                 Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfigurasi Google OAuth',
                        style: TextStyle(fontFamily: 'Display', 
                            fontSize: 19.55, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Langkah pendaftaran Google Cloud Console',
                        style: TextStyle(color: AP.slate, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AP.cloud,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AP.line),
              ),
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agar Google Sign-In aktif di HP fisik / rilis:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Daftarkan SHA-1 debug ini ke Firebase / Google Cloud Console:\n'
                    '   SHA-1: B9:68:02:8D:C9:3E:C5:15:40:26:C7:DF:A2:E9:AC:0B:7C:62:CF:E1\n'
                    '2. Package Name: dev.hellens.ace_padel\n'
                    '3. Unduh google-services.json ke folder android/app/',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        color: AP.ink,
                        fontSize: 11,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
             Text(
              'Untuk pengujian saat ini di emulator, Anda dapat langsung melanjutkan dengan Akun Google Demo/Tester:',
              style: TextStyle(color: AP.slate, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  UserStore.instance.loginWithGoogleAccount(
                    name: 'Afan (Google)',
                    email: 'hanafiafan20@gmail.com',
                    googleId: 'g_10823485729103847',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil masuk dengan akun Google: hanafiafan20@gmail.com'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.circleCheck, size: 20),
                label: const Text('Masuk Akun Google (Afan)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AP.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: Scaffold(
        backgroundColor: AP.cloud,
        body: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              child: SizedBox(
              height: 300,
              child: APPhoto(
              asset: 'assets/images/banner.jpg',
              scrim: .78,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.cover),
                        ),
                      ).popIn(),
                      const SizedBox(height: 18),
                      const Text('Ace Padel',
                          style: TextStyle(fontFamily: 'Display', fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8))
                          .reveal(1),
                      const SizedBox(height: 6),
                      Text('Booking lapangan padel, tanpa ribet.',
                          style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 14))
                          .reveal(2),
                    ],
                  ),
                ),
              ),
            ))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                     Text('Selamat Datang',
                        style: TextStyle(fontFamily: 'Display', fontSize: 24.64, fontWeight: FontWeight.w800, color: AP.ink, letterSpacing: -0.4))
                        .reveal(3),
                    const SizedBox(height: 6),
                     Text(
                      'Pesan lapangan, ikuti mabar komunitas, dan pantau peringkat leaderboard Anda.',
                      style: TextStyle(color: AP.slate, fontSize: 14, height: 1.4),
                      textAlign: TextAlign.center,
                    ).reveal(4),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AP.line),
                        boxShadow: APShadows.card,
                      ),
                      child: Column(
                        children: [
                          _benefitRow(kRacketIcon, 'Booking Instan & Sewa Raket/Bola'),
                          const SizedBox(height: 12),
                          _benefitRow(LucideIcons.users, 'Komunitas Mabar & Match Terbuka'),
                          const SizedBox(height: 12),
                          _benefitRow(LucideIcons.trophy, 'Peringkat Leaderboard Global & Teman'),
                        ],
                      ),
                    ).reveal(5),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AP.ink,
                          elevation: 1,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          side:  BorderSide(color: AP.line, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildGoogleGLogo(),
                                  const SizedBox(width: 12),
                                   Text('Masuk dengan Google',
                                      style: TextStyle(fontFamily: 'Display', fontSize: 18.4, fontWeight: FontWeight.w800, color: AP.ink)),
                                ],
                              ),
                      ),
                    ).reveal(6),
                    TextButton(
                      onPressed: () {
                        APHaptics.light();
                        UserStore.instance.loginAsGuest();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Masuk dalam Mode Tamu (Guest).')),
                        );
                      },
                      child:  Text('Lanjutkan sebagai Tamu (Guest)',
                          style: TextStyle(color: AP.slate, fontWeight: FontWeight.w700, fontSize: 14)),
                    ).reveal(7),
                    TextButton.icon(
                      onPressed: () => _showGoogleConfigModal(''),
                      icon:  Icon(LucideIcons.circleHelp, size: 14, color: AP.slate),
                      label:  Text('Panduan & Credentials Google Console',
                          style: TextStyle(
                              color: AP.slate, fontWeight: FontWeight.w600, fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const APBallIcon(size: 13, color: AP.limeDark),
                            const SizedBox(width: 6),
                             Text('by hellens.dev',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AP.slate, letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AP.lime.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: APGlyph(icon, color: AP.ink, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style:  TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AP.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleGLogo() =>
      Image.asset('assets/images/google_g.png', width: 22, height: 22);
}

