import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kontak dukungan. Ganti dengan nomor/email resmi sebelum rilis.
class APSupport {
  static const whatsapp = '6281234567890'; // format internasional tanpa '+'
  static const email = 'support@acepadel.id';
}

/// Membuka aplikasi eksternal; bila gagal, beri tahu pengguna (tidak diam-diam).
class APLaunch {
  static Future<void> open(BuildContext context, Uri uri, {String failMessage = 'Tidak bisa membuka aplikasi tujuan.'}) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(failMessage)));
  }

  static Future<void> whatsapp(BuildContext c, [String text = 'Halo Ace Padel, saya butuh bantuan.']) =>
      open(c, Uri.parse('https://wa.me/${APSupport.whatsapp}?text=${Uri.encodeComponent(text)}'),
          failMessage: 'WhatsApp tidak tersedia di perangkat ini.');

  static Future<void> email(BuildContext c, [String subject = 'Bantuan Ace Padel']) =>
      open(c, Uri(scheme: 'mailto', path: APSupport.email, queryParameters: {'subject': subject}),
          failMessage: 'Tidak ada aplikasi email. Kirim ke ${APSupport.email}.');

  static Future<void> route(BuildContext c, {required String place, required bool waze}) {
    final q = Uri.encodeComponent(place);
    return open(
      c,
      waze
          ? Uri.parse('https://waze.com/ul?q=$q&navigate=yes')
          : Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'),
      failMessage: 'Tidak bisa membuka peta.',
    );
  }
}
