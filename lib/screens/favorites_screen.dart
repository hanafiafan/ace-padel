import '../core/widgets/ap_shape.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: const Text(
          'Venue Favorit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AnimatedBuilder(
        animation: FavoriteStore.instance,
        builder: (context, _) {
          final favs = FavoriteStore.instance.favoriteCourts;

          if (favs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration:  BoxDecoration(
                        color: AP.surface,
                        shape: BoxShape.circle,
                      ),
                      child:  Icon(
                        LucideIcons.heart,
                        size: 40,
                        color: AP.slate,
                      ),
                    ),
                    const SizedBox(height: 16),
                     Text(
                      'BELUM ADA VENUE FAVORIT',
                      style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                        fontSize: 20.7,
                        fontWeight: FontWeight.w800,
                        color: AP.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                     Text(
                      'Ketuk ikon hati pada lapangan mana pun untuk menyimpannya di sini agar cepat dipesan kembali.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AP.slate, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AP.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: const ChamferBorder(br: 10, tl: 10),
                      ),
                      child: const Text(
                        'Eksplor Lapangan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return APList(
            onRefresh: FavoriteStore.instance.refresh,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                '${favs.length} lapangan tersimpan',
                style:  TextStyle(
                  color: AP.slate,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              ...favs.map((court) => CourtRow(
                    court: court,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(court: court),
                        ),
                      );
                    },
                  )),
            ],
          );
        },
      ),
    );
  }
}
