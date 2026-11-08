import 'package:flutter/material.dart';
import '../../screens/login_screen.dart';
import '../../services/api_service.dart';
import '../../store.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Friendly snackbar for any error thrown by the API layer.
void showError(BuildContext context, Object e) {
  final msg = e is ApiException ? e.message : 'Terjadi kesalahan. Coba lagi.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

void showInfo(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

/// Guests can browse; this gates actions that need an account.
/// Shows a message and opens the login screen. Returns true when logged in.
bool requireLogin(BuildContext context, [String action = 'menggunakan fitur ini']) {
  if (UserStore.instance.isLoggedIn) return true;
  showInfo(context, 'Masuk atau daftar dulu untuk $action.');
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  return false;
}

/// Favorite toggle that requires login and reports API errors.
Future<void> toggleFavorite(BuildContext context, String courtId) async {
  if (!requireLogin(context, 'menyimpan venue favorit')) return;
  try {
    await FavoriteStore.instance.toggle(courtId);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}
