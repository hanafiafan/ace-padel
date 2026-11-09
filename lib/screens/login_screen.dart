import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/responsive_container.dart';
import '../core/widgets/ap_decor.dart';
import '../core/widgets/ap_banners.dart';
import '../core/utils/ui.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _register = false;
  bool _asOwner = false;
  bool _obscure = true;
  String? _formError;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// When pushed from a guest action (requireLogin), return to the caller.
  void _done() {
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    String? err;
    if (_register && name.length < 2) {
      err = 'Nama minimal 2 karakter.';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      err = 'Format email tidak valid.';
    } else if (pass.length < (_register ? 8 : 1)) {
      err = _register ? 'Password minimal 8 karakter.' : 'Masukkan password.';
    }
    if (err != null) {
      setState(() => _formError = err);
      return;
    }
    APHaptics.medium();
    setState(() {
      _isLoading = true;
      _formError = null;
    });
    try {
      if (_register) {
        await UserStore.instance.register(name: name, email: email, password: pass, asOwner: _asOwner);
      } else {
        await UserStore.instance.login(email, pass);
      }
      APHaptics.success();
      _done();
    } on ApiException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          _done();
        }
      }
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
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
              'Atau masuk dengan email & password di halaman login.',
              style: TextStyle(color: AP.slate, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (kDebugMode)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      // Works only on dev servers started with ALLOW_UNVERIFIED_GOOGLE=1.
                      await UserStore.instance.loginWithGoogleAccount(
                        name: 'Google Tester',
                        email: 'google.tester@acepadel.id',
                        googleId: 'dev-google-tester',
                      );
                      _done();
                    } on ApiException catch (e) {
                      if (mounted) showError(context, e);
                    }
                  },
                  icon: const Icon(LucideIcons.circleCheck, size: 20),
                  label: const Text('Masuk Akun Google Tester (dev server)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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
              height: 230,
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
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset('assets/images/logo.png', width: 52, height: 52, fit: BoxFit.cover),
                        ),
                      ).popIn(),
                      const SizedBox(height: 12),
                      const Text('Ace Padel',
                          style: TextStyle(fontFamily: 'Display', fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8))
                          .reveal(1),
                      const SizedBox(height: 4),
                      Text('Booking lapangan padel, tanpa ribet.',
                          style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 14))
                          .reveal(2),
                    ],
                  ),
                ),
              ),
            ))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(_register ? 'Buat Akun Baru' : 'Selamat Datang',
                        style: TextStyle(fontFamily: 'Display', fontSize: 24.64, fontWeight: FontWeight.w800, color: AP.ink, letterSpacing: -0.4))
                        .reveal(3),
                    const SizedBox(height: 6),
                    Text(
                      _register
                          ? 'Daftar untuk memesan lapangan, ikut mabar, dan masuk leaderboard.'
                          : 'Masuk untuk memesan lapangan, ikut mabar, dan pantau peringkat Anda.',
                      style: TextStyle(color: AP.slate, fontSize: 14, height: 1.4),
                      textAlign: TextAlign.center,
                    ).reveal(4),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AP.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AP.line),
                        boxShadow: APShadows.card,
                      ),
                      child: AutofillGroup(
                        child: Column(
                          children: [
                            if (_register) ...[
                              _field(_nameCtrl, 'Nama lengkap', LucideIcons.userRound,
                                  autofill: AutofillHints.name),
                              const SizedBox(height: 12),
                            ],
                            _field(_emailCtrl, 'Email', LucideIcons.mail,
                                type: TextInputType.emailAddress, autofill: AutofillHints.email),
                            const SizedBox(height: 12),
                            _field(_passCtrl, _register ? 'Password (min. 8 karakter)' : 'Password', LucideIcons.lock,
                                obscure: _obscure,
                                autofill: _register ? AutofillHints.newPassword : AutofillHints.password,
                                suffix: IconButton(
                                  icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: AP.slate),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                onSubmit: (_) => _submit()),
                            if (_register)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('Saya pemilik lapangan (mitra)',
                                          style: TextStyle(color: AP.slate, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                    Switch(value: _asOwner, onChanged: (v) => setState(() => _asOwner = v)),
                                  ],
                                ),
                              ),
                            if (_formError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.circleAlert, size: 16, color: Colors.red),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(_formError!,
                                          style: const TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AP.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Text(_register ? 'Daftar' : 'Masuk',
                                        style: const TextStyle(fontFamily: 'Display', fontSize: 18, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _register = !_register;
                                _formError = null;
                              }),
                              child: Text(_register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
                                  style: TextStyle(color: AP.blue, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ).reveal(5),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: Divider(color: AP.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('atau', style: TextStyle(color: AP.slate, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: AP.line)),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AP.surface,
                          foregroundColor: AP.ink,
                          elevation: 1,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          side: BorderSide(color: AP.line, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
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
                    if (!Navigator.canPop(context))
                      TextButton(
                        onPressed: () {
                          APHaptics.light();
                          UserStore.instance.enterGuest();
                        },
                        child: Text('Lihat-lihat dulu sebagai Tamu',
                            style: TextStyle(color: AP.slate, fontWeight: FontWeight.w700, fontSize: 14)),
                      ).reveal(7),
                    TextButton.icon(
                      onPressed: () => _showGoogleConfigModal(''),
                      icon: Icon(LucideIcons.circleHelp, size: 14, color: AP.slate),
                      label: Text('Panduan & Credentials Google Console',
                          style: TextStyle(
                              color: AP.slate, fontWeight: FontWeight.w600, fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 4),
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

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? type, bool obscure = false, Widget? suffix, String? autofill, ValueChanged<String>? onSubmit}) {
    return TextField(
      controller: c,
      keyboardType: type,
      obscureText: obscure,
      autofillHints: autofill == null ? null : [autofill],
      onSubmitted: onSubmit,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AP.cloud,
        prefixIcon: Icon(icon, color: AP.slate, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildGoogleGLogo() =>
      Image.asset('assets/images/google_g.png', width: 22, height: 22);
}

