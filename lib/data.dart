import 'package:flutter/material.dart';
import 'core/widgets/ap_decor.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Court {
  final String id;
  final String name;
  final String venue;
  final String area;
  final double rating;
  final int pricePerHour; // in thousands IDR
  final bool indoor;
  // Seragam untuk semua venue (tint foto): hitam → biru brand.
  List<Color> get gradient => const [Color(0xFF070A16), Color(0xFF1F3BFF)];
  final String image; // bundled asset path, or server path (/img/.. /uploads/..)
  final String imageUrl; // server path used when the bundled asset is missing
  final List<String> facilities;
  final String description;

  const Court({
    required this.id,
    required this.name,
    required this.venue,
    required this.area,
    required this.rating,
    required this.pricePerHour,
    required this.indoor,
    List<Color>? gradient, // ignored: lihat getter di atas
    required this.image,
    this.imageUrl = '',
    this.facilities = const [
      'Sewa Raket & Bola',
      'Shower Air Panas',
      'Locker Room',
      'WiFi Cepat',
      'Parkir Luas',
      'Padel Cafe',
    ],
    this.description =
        'Lapangan padel standar internasional dengan karpet Mondo Supercourt generasi terbaru dan kaca tempered panoramic view untuk kenyamanan bermain maksimal.',
  });

  /// City part of "District, City".
  String get city => area.contains(',') ? area.split(',').last.trim() : area;

  factory Court.fromJson(Map<String, dynamic> m) {
    final img = (m['image'] as String?) ?? '';
    final url = (m['imageUrl'] as String?) ?? '';
    return Court(
      id: '${m['id']}',
      name: (m['name'] as String?) ?? '',
      venue: (m['venue'] as String?) ?? '',
      area: (m['area'] as String?) ?? '',
      rating: (m['rating'] as num?)?.toDouble() ?? 0,
      pricePerHour: (m['pricePerHour'] as num?)?.toInt() ?? 0,
      indoor: m['indoor'] == true || m['indoor'] == 1,
      image: img.startsWith('assets/') ? img : (url.isNotEmpty ? url : img),
      imageUrl: url,
      facilities: (m['facilities'] as List?)?.map((e) => '$e').toList() ?? const [],
      description: (m['description'] as String?) ?? '',
    );
  }
}

/// Unique cities, sorted — for the city filter.
List<String> get cities {
  final set = courts.map((c) => c.city).toSet().toList();
  set.sort();
  return set;
}

class Booking {
  final String id;
  final Court court;
  final DateTime date; // day only
  final String slot; // e.g. "18:00"
  final int durationMinutes;
  final String paymentMethod;
  final String? voucherCode;
  final int discount;
  final List<String> addOns;
  final int addOnsTotal;
  final String status; // 'Terkonfirmasi', 'Check-in Selesai', 'Dibatalkan', 'Maintenance'
  final DateTime createdAt;
  // Server-owned fields
  final String paymentStatus; // 'Belum Bayar' | 'Menunggu' | 'Lunas' | ...
  final String? paymentRef; // VA number / QRIS payload
  final DateTime? paymentExpiresAt;
  final String? paymentUrl; // DOKU hosted payment page (set after checkout)
  final int? serverFinalPrice; // thousands of Rupiah, computed by the server
  final String? userName;
  final String? note;

  Booking({
    String? id,
    required this.court,
    required this.date,
    required this.slot,
    this.durationMinutes = 60,
    this.paymentMethod = 'Bayar di tempat',
    this.voucherCode,
    this.discount = 0,
    this.addOns = const [],
    this.addOnsTotal = 0,
    this.status = 'Terkonfirmasi',
    DateTime? createdAt,
    this.paymentStatus = 'Belum Bayar',
    this.paymentRef,
    this.paymentExpiresAt,
    this.paymentUrl,
    this.serverFinalPrice,
    this.userName,
    this.note,
  })  : id = id ?? 'ACE-${court.id.toUpperCase()}-${slot.replaceAll(':', '').replaceAll(' ', '')}',
        createdAt = createdAt ?? DateTime.now();

  factory Booking.fromJson(Map<String, dynamic> m) {
    final cj = m['court'];
    final court = cj is Map<String, dynamic>
        ? Court.fromJson(cj)
        : (courts.where((c) => c.id == m['courtId']).firstOrNull ??
            Court(id: '${m['courtId']}', name: 'Lapangan', venue: '', area: '', rating: 0, pricePerHour: (m['pricePerHour'] as num?)?.toInt() ?? 0, indoor: true, image: ''));
    final d = DateTime.parse('${m['date']}'.split('T').first);
    return Booking(
      id: '${m['id']}',
      court: court,
      date: DateTime(d.year, d.month, d.day),
      slot: '${m['slot']}',
      paymentMethod: (m['paymentMethod'] as String?) ?? 'Bayar di tempat',
      voucherCode: m['voucherCode'] as String?,
      discount: (m['discount'] as num?)?.toInt() ?? 0,
      addOns: (m['addOns'] as List?)?.map((e) => '$e').toList() ?? const [],
      addOnsTotal: (m['addOnsTotal'] as num?)?.toInt() ?? 0,
      status: (m['status'] as String?) ?? 'Terkonfirmasi',
      createdAt: DateTime.tryParse('${m['createdAt']}')?.toLocal(),
      paymentStatus: (m['paymentStatus'] as String?) ?? 'Belum Bayar',
      paymentRef: m['paymentRef'] as String?,
      paymentExpiresAt: DateTime.tryParse('${m['paymentExpiresAt']}')?.toLocal(),
      paymentUrl: m['paymentUrl'] as String?,
      serverFinalPrice: (m['finalPrice'] as num?)?.toInt(),
      userName: m['userName'] as String?,
      note: m['note'] as String?,
    );
  }

  int get baseCourtPrice => (court.pricePerHour * durationMinutes / 60).round();
  int get finalPrice =>
      serverFinalPrice ?? (baseCourtPrice + addOnsTotal - discount).clamp(0, 999999);

  String get key => '${court.id}|${date.year}-${date.month}-${date.day}|$slot';

  bool get isCheckedIn => status == 'Check-in Selesai';
  bool get isMaintenance => status == 'Maintenance';
  bool get isCancelled => status == 'Dibatalkan';
  bool get isPendingPayment => status == 'Terkonfirmasi' && paymentStatus == 'Menunggu';
  bool get isPaid => paymentStatus == 'Lunas';

  Booking copyWith({String? status, String? paymentStatus, String? paymentUrl}) => Booking(
        id: id,
        court: court,
        date: date,
        slot: slot,
        durationMinutes: durationMinutes,
        paymentMethod: paymentMethod,
        voucherCode: voucherCode,
        discount: discount,
        addOns: addOns,
        addOnsTotal: addOnsTotal,
        status: status ?? this.status,
        createdAt: createdAt,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentRef: paymentRef,
        paymentExpiresAt: paymentExpiresAt,
        paymentUrl: paymentUrl ?? this.paymentUrl,
        serverFinalPrice: serverFinalPrice,
        userName: userName,
        note: note,
      );
}

/// Offline fallback catalog (used only when the server is unreachable).
const fallbackCourts = <Court>[
  Court(
    id: 'c1',
    name: 'Signature Pink Indoor Court',
    venue: 'Padel Pro Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.8,
    pricePerHour: 220,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_padel_pro_kemang.jpg',
    facilities: ['Karpet Pink WPT', 'Full AC & High Ceiling', 'Matchmaking Service', 'Padel Cafe', 'Shower Air Panas', 'Parkir Luas'],
    description: 'Klub padel indoor premier di Kemang dengan 6 lapangan ber-AC, karpet pink ikonik, fasilitas cafe, dan pro shop terlengkap.',
  ),
  Court(
    id: 'c2',
    name: 'Menteng Panoramic Glass',
    venue: 'Social Padel House Menteng',
    area: 'Menteng, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_social_menteng.jpg',
    facilities: ['5 Lapangan Indoor', 'Lounge Bar & Cafe', 'Kaca Panoramic 12mm', 'Mix-ins & Social Play', 'Pro Shop', 'WiFi Cepat'],
    description: '5 lapangan padel indoor modern di pusat Jakarta dengan lounge bar berkelas, ruang ganti mewah, dan komunitas aktif.',
  ),
  Court(
    id: 'c3',
    name: 'Center Glass Court',
    venue: 'Social Padel House Setiabudi',
    area: 'Setiabudi, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_social_setiabudi.jpg',
    facilities: ['Kaca Tempered 12mm', 'LED 600 Lux Anti-Silau', 'Locker Room VIP', 'Cold Plunge', 'Kafe & Juice Bar', 'Valet Parking'],
    description: 'Lapangan panoramic kaca tempered 12mm anti-shatter di segitiga emas Setiabudi dengan pencahayaan LED 600 Lux turnamen.',
  ),
  Court(
    id: 'c4',
    name: 'Beachfront Sunset Court',
    venue: 'HPC Atlas Beach Club',
    area: 'Canggu, Badung',
    rating: 4.7,
    pricePerHour: 340,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_hpc_atlas_bali.jpg',
    facilities: ['Beachfront Ocean View', 'Floodlit Night Play', 'Akses Beach Club', 'Changing Rooms & Shower', 'Towel Service', 'Sunset Lounge'],
    description: 'Main padel outdoor tepat di tepi Pantai Berawa Canggu dengan suasana sunset spektakuler dan akses langsung ke beach club.',
  ),
  Court(
    id: 'c5',
    name: 'Grand Arena Hall',
    venue: 'Rekket Space Padel Hall',
    area: 'BSD, Tangerang',
    rating: 4.8,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_rekket_bsd.jpg',
    facilities: ['Run-off Space 3 Meter', 'Karpet Mondo Supercourt', 'Pro Coaching Clinic', 'Kids Padel Clinic', 'Tribun Penonton', 'Parkir 100+ Mobil'],
    description: 'Padel hall terbesar di kawasan BSD dengan 3 meter run-off space, karpet Mondo, dan program klinik pembinaan atlet.',
  ),
  Court(
    id: 'c6',
    name: 'Verde Championship Court',
    venue: 'Verde Sports Hub PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.8,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_verde_pik2.jpg',
    facilities: ['World Padel Tour Specs', 'Clubhouse & Restaurant', 'Smart Replay Camera', 'Locker Room Mewah', 'Toko Raket Bullpadel', 'Outdoor Deck'],
    description: 'Sports hub prestisius di kawasan PIK 2 dengan lapangan berstandar World Padel Tour dan fasilitas olahraga terpadu.',
  ),
  Court(
    id: 'c7',
    name: 'Monas Panoramic Arena',
    venue: 'Nine Padel Monas',
    area: 'Gambir, Jakarta',
    rating: 4.8,
    pricePerHour: 230,
    indoor: true,
    gradient: [Color(0xFF5B2AA8), Color(0xFF8046D8)],
    image: 'assets/images/court_nine_monas.jpg',
    facilities: ['Akses MRT & KRL', 'Zero-Glare LED', 'Sewa Raket Babolat', 'Cafe & Healthy Bar', 'Shower Air Panas', 'Musholla Nyaman'],
    description: 'Lapangan padel strategis di jantung kota Jakarta dengan akses langsung MRT/KRL dan pencahayaan bebas silau.',
  ),
  Court(
    id: 'c8',
    name: 'Tropical Oasis Court',
    venue: 'Bali Social Club Canggu',
    area: 'Canggu, Badung',
    rating: 4.6,
    pricePerHour: 290,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_bali_social_club.jpg',
    facilities: ['Cold Plunge Ice Bath', 'Sauna Kayu Jati', 'Organic Cafe & Smoothies', 'Tropical Garden Vibe', 'Shower Outdoor', 'Komunitas Internasional'],
    description: 'Sanctuary padel dengan sentuhan tropis Canggu, recovery cold plunge pool, sauna kayu jati, dan cafe organik pasca tanding.',
  ),
  Court(
    id: 'c9',
    name: 'Cliffside Pro Arena',
    venue: 'Monster Padel Uluwatu',
    area: 'Uluwatu, Badung',
    rating: 4.6,
    pricePerHour: 280,
    indoor: false,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_monster_uluwatu.jpg',
    facilities: ['Cliffside Ocean Breeze', 'Anti-Slip FIP Turf', 'Sunset Viewing Lounge', 'Cocktail & Healthy Bar', 'Sewa Sepatu & Raket', 'Pro Sparring'],
    description: 'Lapangan outdoor spektakuler di atas tebing Uluwatu dengan semilir angin laut dan karpet anti-slip standar FIP.',
  ),
  Court(
    id: 'c10',
    name: 'Shortcut Jungle Court',
    venue: 'Jungle Padel Canggu',
    area: 'Pererenan, Badung',
    rating: 4.9,
    pricePerHour: 270,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_jungle_canggu.jpg',
    facilities: ['Green Ricefield View', '4 Lapangan Semi-Outdoor', 'Komunitas Mabar Harian', 'Cafe & Fresh Coconut', 'Locker Room', 'Pet Friendly'],
    description: 'Pionir klub padel pertama di Bali dengan pemandangan sawah alami dan suasana komunitas mabar yang guyub.',
  ),
  Court(
    id: 'c11',
    name: 'High-Tech Glass Arena',
    venue: 'SPACE PADEL PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 5.0,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_space_pik2.webp',
    facilities: ['Smart Instant Replay', 'Digital Scoreboard', 'VIP Player Lounge', 'Loker Elektronik', 'Shower Bertekanan Tinggi', 'Parkir Basement'],
    description: 'Arena padel futuristik dilengkapi smart camera untuk merekam poin terbaik dan replay gerakan smash secara otomatis.',
  ),
  Court(
    id: 'c12',
    name: 'Boutique Glass Court',
    venue: 'Maison de Padel',
    area: 'Kebon Jeruk, Jakarta',
    rating: 4.9,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_maison_de_padel.webp',
    facilities: ['Boutique Private Courts', 'FIP Certified Coaching', 'Artisan Coffee Bar', 'Shower Air Panas', 'WiFi High-Speed', 'Private Event Booking'],
    description: 'Klub padel boutique di Jakarta Barat dengan suasana privat eksklusif dan bimbingan pelatih bersertifikasi FIP.',
  ),
  Court(
    id: 'c13',
    name: 'Urban Lifestyle Court',
    venue: 'Artepola Padel Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.5,
    pricePerHour: 200,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_artepola_kemang.webp',
    facilities: ['Lifestyle Bistro Cafe', 'Full Air Conditioner', 'DJ Night Sessions', 'Locker Room Luas', 'Sewa Raket Head & Nox', 'Parkir Valet'],
    description: 'Tempat favorit komunitas urban lifestyle Jakarta Selatan untuk bermain padel dan hangout sore di bistro artisan.',
  ),
  Court(
    id: 'c14',
    name: 'Industrial High-Loft',
    venue: 'Warehaus Padel Tangerang',
    area: 'Alam Sutera, Tangerang',
    rating: 4.8,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_warehaus_tangerang.webp',
    facilities: ['High Ceiling 11 Meter', 'Sirkulasi Udara Natural', 'Zero-Glare LED Lighting', 'Pro Shop Terlengkap', 'Musholla & Shower', 'Resto & Cafe'],
    description: 'Desain open-hall warehouse berplafon setinggi 11 meter dengan sirkulasi udara optimal dan zero-glare lighting.',
  ),
  Court(
    id: 'c15',
    name: 'Zenith Glass Court',
    venue: 'Aman Padel Denpasar',
    area: 'Denpasar Barat, Denpasar',
    rating: 4.6,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_aman_denpasar.jpg',
    facilities: ['Pusat Kota Denpasar', 'Indoor Anti-Hujan', 'Sewa Raket Babolat', 'Locker Room', 'Area Nonton Mezzanine', 'Minuman Isotonik Dingin'],
    description: 'Padel court modern di pusat kota Denpasar dengan sewa raket premium, toko perlengkapan, dan ruang ganti bersih.',
  ),
  Court(
    id: 'c16',
    name: 'Sanctuary Valley Court',
    venue: 'TAO Padel Academy Ubud',
    area: 'Ubud, Gianyar',
    rating: 4.8,
    pricePerHour: 230,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_tao_ubud.jpg',
    facilities: ['Pemandangan Lembah Ubud', 'Akademi Pelatihan FIP', 'Meditation & Yoga Deck', 'Organic Healthy Bowls', 'Shower Outdoor', 'Klinik Fisioterapi'],
    description: 'Akademi padel di tengah ketenangan alam Ubud dengan program pelatihan intensif pemula hingga atlet pro.',
  ),
  Court(
    id: 'c17',
    name: 'Signature Pink Indoor Court 2',
    venue: 'Padel Pro Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.7,
    pricePerHour: 220,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_padel_pro_kemang.jpg',
    facilities: ['Karpet Pink WPT', 'Full AC & High Ceiling', 'Matchmaking Service', 'Padel Cafe', 'Shower Air Panas', 'Parkir Luas'],
    description: 'Klub padel indoor premier di Kemang dengan 6 lapangan ber-AC, karpet pink ikonik, fasilitas cafe, dan pro shop terlengkap.',
  ),
  Court(
    id: 'c18',
    name: 'Menteng Panoramic Glass 2',
    venue: 'Social Padel House Menteng',
    area: 'Menteng, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_social_menteng.jpg',
    facilities: ['5 Lapangan Indoor', 'Lounge Bar & Cafe', 'Kaca Panoramic 12mm', 'Mix-ins & Social Play', 'Pro Shop', 'WiFi Cepat'],
    description: '5 lapangan padel indoor modern di pusat Jakarta dengan lounge bar berkelas, ruang ganti mewah, dan komunitas aktif.',
  ),
  Court(
    id: 'c19',
    name: 'Center Glass Court 2',
    venue: 'Social Padel House Setiabudi',
    area: 'Setiabudi, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_social_setiabudi.jpg',
    facilities: ['Kaca Tempered 12mm', 'LED 600 Lux Anti-Silau', 'Locker Room VIP', 'Cold Plunge', 'Kafe & Juice Bar', 'Valet Parking'],
    description: 'Lapangan panoramic kaca tempered 12mm anti-shatter di segitiga emas Setiabudi dengan pencahayaan LED 600 Lux turnamen.',
  ),
  Court(
    id: 'c20',
    name: 'Beachfront Sunset Court 2',
    venue: 'HPC Atlas Beach Club',
    area: 'Canggu, Badung',
    rating: 4.9,
    pricePerHour: 340,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_hpc_atlas_bali.jpg',
    facilities: ['Beachfront Ocean View', 'Floodlit Night Play', 'Akses Beach Club', 'Changing Rooms & Shower', 'Towel Service', 'Sunset Lounge'],
    description: 'Main padel outdoor tepat di tepi Pantai Berawa Canggu dengan suasana sunset spektakuler dan akses langsung ke beach club.',
  ),
  Court(
    id: 'c21',
    name: 'Grand Arena Hall 2',
    venue: 'Rekket Space Padel Hall',
    area: 'BSD, Tangerang',
    rating: 4.8,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_rekket_bsd.jpg',
    facilities: ['Run-off Space 3 Meter', 'Karpet Mondo Supercourt', 'Pro Coaching Clinic', 'Kids Padel Clinic', 'Tribun Penonton', 'Parkir 100+ Mobil'],
    description: 'Padel hall terbesar di kawasan BSD dengan 3 meter run-off space, karpet Mondo, dan program klinik pembinaan atlet.',
  ),
  Court(
    id: 'c22',
    name: 'Verde Championship Court 2',
    venue: 'Verde Sports Hub PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.7,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_verde_pik2.jpg',
    facilities: ['World Padel Tour Specs', 'Clubhouse & Restaurant', 'Smart Replay Camera', 'Locker Room Mewah', 'Toko Raket Bullpadel', 'Outdoor Deck'],
    description: 'Sports hub prestisius di kawasan PIK 2 dengan lapangan berstandar World Padel Tour dan fasilitas olahraga terpadu.',
  ),
  Court(
    id: 'c23',
    name: 'Monas Panoramic Arena 2',
    venue: 'Nine Padel Monas',
    area: 'Gambir, Jakarta',
    rating: 4.8,
    pricePerHour: 230,
    indoor: true,
    gradient: [Color(0xFF5B2AA8), Color(0xFF8046D8)],
    image: 'assets/images/court_nine_monas.jpg',
    facilities: ['Akses MRT & KRL', 'Zero-Glare LED', 'Sewa Raket Babolat', 'Cafe & Healthy Bar', 'Shower Air Panas', 'Musholla Nyaman'],
    description: 'Lapangan padel strategis di jantung kota Jakarta dengan akses langsung MRT/KRL dan pencahayaan bebas silau.',
  ),
  Court(
    id: 'c24',
    name: 'Tropical Oasis Court 2',
    venue: 'Bali Social Club Canggu',
    area: 'Canggu, Badung',
    rating: 4.6,
    pricePerHour: 290,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_bali_social_club.jpg',
    facilities: ['Cold Plunge Ice Bath', 'Sauna Kayu Jati', 'Organic Cafe & Smoothies', 'Tropical Garden Vibe', 'Shower Outdoor', 'Komunitas Internasional'],
    description: 'Sanctuary padel dengan sentuhan tropis Canggu, recovery cold plunge pool, sauna kayu jati, dan cafe organik pasca tanding.',
  ),
  Court(
    id: 'c25',
    name: 'Cliffside Pro Arena 2',
    venue: 'Monster Padel Uluwatu',
    area: 'Uluwatu, Badung',
    rating: 4.8,
    pricePerHour: 280,
    indoor: false,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_monster_uluwatu.jpg',
    facilities: ['Cliffside Ocean Breeze', 'Anti-Slip FIP Turf', 'Sunset Viewing Lounge', 'Cocktail & Healthy Bar', 'Sewa Sepatu & Raket', 'Pro Sparring'],
    description: 'Lapangan outdoor spektakuler di atas tebing Uluwatu dengan semilir angin laut dan karpet anti-slip standar FIP.',
  ),
  Court(
    id: 'c26',
    name: 'Shortcut Jungle Court 2',
    venue: 'Jungle Padel Canggu',
    area: 'Pererenan, Badung',
    rating: 4.9,
    pricePerHour: 270,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_jungle_canggu.jpg',
    facilities: ['Green Ricefield View', '4 Lapangan Semi-Outdoor', 'Komunitas Mabar Harian', 'Cafe & Fresh Coconut', 'Locker Room', 'Pet Friendly'],
    description: 'Pionir klub padel pertama di Bali dengan pemandangan sawah alami dan suasana komunitas mabar yang guyub.',
  ),
  Court(
    id: 'c27',
    name: 'High-Tech Glass Arena 2',
    venue: 'SPACE PADEL PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.9,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_space_pik2.webp',
    facilities: ['Smart Instant Replay', 'Digital Scoreboard', 'VIP Player Lounge', 'Loker Elektronik', 'Shower Bertekanan Tinggi', 'Parkir Basement'],
    description: 'Arena padel futuristik dilengkapi smart camera untuk merekam poin terbaik dan replay gerakan smash secara otomatis.',
  ),
  Court(
    id: 'c28',
    name: 'Boutique Glass Court 2',
    venue: 'Maison de Padel',
    area: 'Kebon Jeruk, Jakarta',
    rating: 4.8,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_maison_de_padel.webp',
    facilities: ['Boutique Private Courts', 'FIP Certified Coaching', 'Artisan Coffee Bar', 'Shower Air Panas', 'WiFi High-Speed', 'Private Event Booking'],
    description: 'Klub padel boutique di Jakarta Barat dengan suasana privat eksklusif dan bimbingan pelatih bersertifikasi FIP.',
  ),
  Court(
    id: 'c29',
    name: 'Urban Lifestyle Court 2',
    venue: 'Artepola Padel Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.5,
    pricePerHour: 200,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_artepola_kemang.webp',
    facilities: ['Lifestyle Bistro Cafe', 'Full Air Conditioner', 'DJ Night Sessions', 'Locker Room Luas', 'Sewa Raket Head & Nox', 'Parkir Valet'],
    description: 'Tempat favorit komunitas urban lifestyle Jakarta Selatan untuk bermain padel dan hangout sore di bistro artisan.',
  ),
  Court(
    id: 'c30',
    name: 'Industrial High-Loft 2',
    venue: 'Warehaus Padel Tangerang',
    area: 'Alam Sutera, Tangerang',
    rating: 5.0,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_warehaus_tangerang.webp',
    facilities: ['High Ceiling 11 Meter', 'Sirkulasi Udara Natural', 'Zero-Glare LED Lighting', 'Pro Shop Terlengkap', 'Musholla & Shower', 'Resto & Cafe'],
    description: 'Desain open-hall warehouse berplafon setinggi 11 meter dengan sirkulasi udara optimal dan zero-glare lighting.',
  ),
  Court(
    id: 'c31',
    name: 'Zenith Glass Court 2',
    venue: 'Aman Padel Denpasar',
    area: 'Denpasar Barat, Denpasar',
    rating: 4.5,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_aman_denpasar.jpg',
    facilities: ['Pusat Kota Denpasar', 'Indoor Anti-Hujan', 'Sewa Raket Babolat', 'Locker Room', 'Area Nonton Mezzanine', 'Minuman Isotonik Dingin'],
    description: 'Padel court modern di pusat kota Denpasar dengan sewa raket premium, toko perlengkapan, dan ruang ganti bersih.',
  ),
  Court(
    id: 'c32',
    name: 'Sanctuary Valley Court 2',
    venue: 'TAO Padel Academy Ubud',
    area: 'Ubud, Gianyar',
    rating: 4.7,
    pricePerHour: 230,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_tao_ubud.jpg',
    facilities: ['Pemandangan Lembah Ubud', 'Akademi Pelatihan FIP', 'Meditation & Yoga Deck', 'Organic Healthy Bowls', 'Shower Outdoor', 'Klinik Fisioterapi'],
    description: 'Akademi padel di tengah ketenangan alam Ubud dengan program pelatihan intensif pemula hingga atlet pro.',
  ),
  Court(
    id: 'c33',
    name: 'Signature Pink Indoor Court 3',
    venue: 'Padel Pro Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.6,
    pricePerHour: 220,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_padel_pro_kemang.jpg',
    facilities: ['Karpet Pink WPT', 'Full AC & High Ceiling', 'Matchmaking Service', 'Padel Cafe', 'Shower Air Panas', 'Parkir Luas'],
    description: 'Klub padel indoor premier di Kemang dengan 6 lapangan ber-AC, karpet pink ikonik, fasilitas cafe, dan pro shop terlengkap.',
  ),
  Court(
    id: 'c34',
    name: 'Menteng Panoramic Glass 3',
    venue: 'Social Padel House Menteng',
    area: 'Menteng, Jakarta',
    rating: 4.7,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_social_menteng.jpg',
    facilities: ['5 Lapangan Indoor', 'Lounge Bar & Cafe', 'Kaca Panoramic 12mm', 'Mix-ins & Social Play', 'Pro Shop', 'WiFi Cepat'],
    description: '5 lapangan padel indoor modern di pusat Jakarta dengan lounge bar berkelas, ruang ganti mewah, dan komunitas aktif.',
  ),
  Court(
    id: 'c35',
    name: 'Center Glass Court 3',
    venue: 'Social Padel House Setiabudi',
    area: 'Setiabudi, Jakarta',
    rating: 5.0,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_social_setiabudi.jpg',
    facilities: ['Kaca Tempered 12mm', 'LED 600 Lux Anti-Silau', 'Locker Room VIP', 'Cold Plunge', 'Kafe & Juice Bar', 'Valet Parking'],
    description: 'Lapangan panoramic kaca tempered 12mm anti-shatter di segitiga emas Setiabudi dengan pencahayaan LED 600 Lux turnamen.',
  ),
  Court(
    id: 'c36',
    name: 'Beachfront Sunset Court 3',
    venue: 'HPC Atlas Beach Club',
    area: 'Canggu, Badung',
    rating: 4.9,
    pricePerHour: 340,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_hpc_atlas_bali.jpg',
    facilities: ['Beachfront Ocean View', 'Floodlit Night Play', 'Akses Beach Club', 'Changing Rooms & Shower', 'Towel Service', 'Sunset Lounge'],
    description: 'Main padel outdoor tepat di tepi Pantai Berawa Canggu dengan suasana sunset spektakuler dan akses langsung ke beach club.',
  ),
  Court(
    id: 'c37',
    name: 'Grand Arena Hall 3',
    venue: 'Rekket Space Padel Hall',
    area: 'BSD, Tangerang',
    rating: 4.7,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_rekket_bsd.jpg',
    facilities: ['Run-off Space 3 Meter', 'Karpet Mondo Supercourt', 'Pro Coaching Clinic', 'Kids Padel Clinic', 'Tribun Penonton', 'Parkir 100+ Mobil'],
    description: 'Padel hall terbesar di kawasan BSD dengan 3 meter run-off space, karpet Mondo, dan program klinik pembinaan atlet.',
  ),
  Court(
    id: 'c38',
    name: 'Verde Championship Court 3',
    venue: 'Verde Sports Hub PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.6,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_verde_pik2.jpg',
    facilities: ['World Padel Tour Specs', 'Clubhouse & Restaurant', 'Smart Replay Camera', 'Locker Room Mewah', 'Toko Raket Bullpadel', 'Outdoor Deck'],
    description: 'Sports hub prestisius di kawasan PIK 2 dengan lapangan berstandar World Padel Tour dan fasilitas olahraga terpadu.',
  ),
  Court(
    id: 'c39',
    name: 'Monas Panoramic Arena 3',
    venue: 'Nine Padel Monas',
    area: 'Gambir, Jakarta',
    rating: 4.7,
    pricePerHour: 230,
    indoor: true,
    gradient: [Color(0xFF5B2AA8), Color(0xFF8046D8)],
    image: 'assets/images/court_nine_monas.jpg',
    facilities: ['Akses MRT & KRL', 'Zero-Glare LED', 'Sewa Raket Babolat', 'Cafe & Healthy Bar', 'Shower Air Panas', 'Musholla Nyaman'],
    description: 'Lapangan padel strategis di jantung kota Jakarta dengan akses langsung MRT/KRL dan pencahayaan bebas silau.',
  ),
  Court(
    id: 'c40',
    name: 'Tropical Oasis Court 3',
    venue: 'Bali Social Club Canggu',
    area: 'Canggu, Badung',
    rating: 4.8,
    pricePerHour: 290,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_bali_social_club.jpg',
    facilities: ['Cold Plunge Ice Bath', 'Sauna Kayu Jati', 'Organic Cafe & Smoothies', 'Tropical Garden Vibe', 'Shower Outdoor', 'Komunitas Internasional'],
    description: 'Sanctuary padel dengan sentuhan tropis Canggu, recovery cold plunge pool, sauna kayu jati, dan cafe organik pasca tanding.',
  ),
  Court(
    id: 'c41',
    name: 'Cliffside Pro Arena 3',
    venue: 'Monster Padel Uluwatu',
    area: 'Uluwatu, Badung',
    rating: 4.8,
    pricePerHour: 280,
    indoor: false,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_monster_uluwatu.jpg',
    facilities: ['Cliffside Ocean Breeze', 'Anti-Slip FIP Turf', 'Sunset Viewing Lounge', 'Cocktail & Healthy Bar', 'Sewa Sepatu & Raket', 'Pro Sparring'],
    description: 'Lapangan outdoor spektakuler di atas tebing Uluwatu dengan semilir angin laut dan karpet anti-slip standar FIP.',
  ),
  Court(
    id: 'c42',
    name: 'Shortcut Jungle Court 3',
    venue: 'Jungle Padel Canggu',
    area: 'Pererenan, Badung',
    rating: 4.8,
    pricePerHour: 270,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_jungle_canggu.jpg',
    facilities: ['Green Ricefield View', '4 Lapangan Semi-Outdoor', 'Komunitas Mabar Harian', 'Cafe & Fresh Coconut', 'Locker Room', 'Pet Friendly'],
    description: 'Pionir klub padel pertama di Bali dengan pemandangan sawah alami dan suasana komunitas mabar yang guyub.',
  ),
  Court(
    id: 'c43',
    name: 'High-Tech Glass Arena 3',
    venue: 'SPACE PADEL PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.8,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_space_pik2.webp',
    facilities: ['Smart Instant Replay', 'Digital Scoreboard', 'VIP Player Lounge', 'Loker Elektronik', 'Shower Bertekanan Tinggi', 'Parkir Basement'],
    description: 'Arena padel futuristik dilengkapi smart camera untuk merekam poin terbaik dan replay gerakan smash secara otomatis.',
  ),
  Court(
    id: 'c44',
    name: 'Boutique Glass Court 3',
    venue: 'Maison de Padel',
    area: 'Kebon Jeruk, Jakarta',
    rating: 4.8,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_maison_de_padel.webp',
    facilities: ['Boutique Private Courts', 'FIP Certified Coaching', 'Artisan Coffee Bar', 'Shower Air Panas', 'WiFi High-Speed', 'Private Event Booking'],
    description: 'Klub padel boutique di Jakarta Barat dengan suasana privat eksklusif dan bimbingan pelatih bersertifikasi FIP.',
  ),
  Court(
    id: 'c45',
    name: 'Urban Lifestyle Court 3',
    venue: 'Artepola Padel Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.7,
    pricePerHour: 200,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_artepola_kemang.webp',
    facilities: ['Lifestyle Bistro Cafe', 'Full Air Conditioner', 'DJ Night Sessions', 'Locker Room Luas', 'Sewa Raket Head & Nox', 'Parkir Valet'],
    description: 'Tempat favorit komunitas urban lifestyle Jakarta Selatan untuk bermain padel dan hangout sore di bistro artisan.',
  ),
  Court(
    id: 'c46',
    name: 'Industrial High-Loft 3',
    venue: 'Warehaus Padel Tangerang',
    area: 'Alam Sutera, Tangerang',
    rating: 5.0,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_warehaus_tangerang.webp',
    facilities: ['High Ceiling 11 Meter', 'Sirkulasi Udara Natural', 'Zero-Glare LED Lighting', 'Pro Shop Terlengkap', 'Musholla & Shower', 'Resto & Cafe'],
    description: 'Desain open-hall warehouse berplafon setinggi 11 meter dengan sirkulasi udara optimal dan zero-glare lighting.',
  ),
  Court(
    id: 'c47',
    name: 'Zenith Glass Court 3',
    venue: 'Aman Padel Denpasar',
    area: 'Denpasar Barat, Denpasar',
    rating: 4.5,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_aman_denpasar.jpg',
    facilities: ['Pusat Kota Denpasar', 'Indoor Anti-Hujan', 'Sewa Raket Babolat', 'Locker Room', 'Area Nonton Mezzanine', 'Minuman Isotonik Dingin'],
    description: 'Padel court modern di pusat kota Denpasar dengan sewa raket premium, toko perlengkapan, dan ruang ganti bersih.',
  ),
  Court(
    id: 'c48',
    name: 'Sanctuary Valley Court 3',
    venue: 'TAO Padel Academy Ubud',
    area: 'Ubud, Gianyar',
    rating: 4.6,
    pricePerHour: 230,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_tao_ubud.jpg',
    facilities: ['Pemandangan Lembah Ubud', 'Akademi Pelatihan FIP', 'Meditation & Yoga Deck', 'Organic Healthy Bowls', 'Shower Outdoor', 'Klinik Fisioterapi'],
    description: 'Akademi padel di tengah ketenangan alam Ubud dengan program pelatihan intensif pemula hingga atlet pro.',
  ),
  Court(
    id: 'c49',
    name: 'Signature Pink Indoor Court 4',
    venue: 'Padel Pro Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.6,
    pricePerHour: 220,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_padel_pro_kemang.jpg',
    facilities: ['Karpet Pink WPT', 'Full AC & High Ceiling', 'Matchmaking Service', 'Padel Cafe', 'Shower Air Panas', 'Parkir Luas'],
    description: 'Klub padel indoor premier di Kemang dengan 6 lapangan ber-AC, karpet pink ikonik, fasilitas cafe, dan pro shop terlengkap.',
  ),
  Court(
    id: 'c50',
    name: 'Menteng Panoramic Glass 4',
    venue: 'Social Padel House Menteng',
    area: 'Menteng, Jakarta',
    rating: 4.9,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_social_menteng.jpg',
    facilities: ['5 Lapangan Indoor', 'Lounge Bar & Cafe', 'Kaca Panoramic 12mm', 'Mix-ins & Social Play', 'Pro Shop', 'WiFi Cepat'],
    description: '5 lapangan padel indoor modern di pusat Jakarta dengan lounge bar berkelas, ruang ganti mewah, dan komunitas aktif.',
  ),
  Court(
    id: 'c51',
    name: 'Center Glass Court 4',
    venue: 'Social Padel House Setiabudi',
    area: 'Setiabudi, Jakarta',
    rating: 5.0,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_social_setiabudi.jpg',
    facilities: ['Kaca Tempered 12mm', 'LED 600 Lux Anti-Silau', 'Locker Room VIP', 'Cold Plunge', 'Kafe & Juice Bar', 'Valet Parking'],
    description: 'Lapangan panoramic kaca tempered 12mm anti-shatter di segitiga emas Setiabudi dengan pencahayaan LED 600 Lux turnamen.',
  ),
  Court(
    id: 'c52',
    name: 'Beachfront Sunset Court 4',
    venue: 'HPC Atlas Beach Club',
    area: 'Canggu, Badung',
    rating: 4.8,
    pricePerHour: 340,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_hpc_atlas_bali.jpg',
    facilities: ['Beachfront Ocean View', 'Floodlit Night Play', 'Akses Beach Club', 'Changing Rooms & Shower', 'Towel Service', 'Sunset Lounge'],
    description: 'Main padel outdoor tepat di tepi Pantai Berawa Canggu dengan suasana sunset spektakuler dan akses langsung ke beach club.',
  ),
  Court(
    id: 'c53',
    name: 'Grand Arena Hall 4',
    venue: 'Rekket Space Padel Hall',
    area: 'BSD, Tangerang',
    rating: 4.6,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_rekket_bsd.jpg',
    facilities: ['Run-off Space 3 Meter', 'Karpet Mondo Supercourt', 'Pro Coaching Clinic', 'Kids Padel Clinic', 'Tribun Penonton', 'Parkir 100+ Mobil'],
    description: 'Padel hall terbesar di kawasan BSD dengan 3 meter run-off space, karpet Mondo, dan program klinik pembinaan atlet.',
  ),
  Court(
    id: 'c54',
    name: 'Verde Championship Court 4',
    venue: 'Verde Sports Hub PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.6,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_verde_pik2.jpg',
    facilities: ['World Padel Tour Specs', 'Clubhouse & Restaurant', 'Smart Replay Camera', 'Locker Room Mewah', 'Toko Raket Bullpadel', 'Outdoor Deck'],
    description: 'Sports hub prestisius di kawasan PIK 2 dengan lapangan berstandar World Padel Tour dan fasilitas olahraga terpadu.',
  ),
  Court(
    id: 'c55',
    name: 'Monas Panoramic Arena 4',
    venue: 'Nine Padel Monas',
    area: 'Gambir, Jakarta',
    rating: 4.9,
    pricePerHour: 230,
    indoor: true,
    gradient: [Color(0xFF5B2AA8), Color(0xFF8046D8)],
    image: 'assets/images/court_nine_monas.jpg',
    facilities: ['Akses MRT & KRL', 'Zero-Glare LED', 'Sewa Raket Babolat', 'Cafe & Healthy Bar', 'Shower Air Panas', 'Musholla Nyaman'],
    description: 'Lapangan padel strategis di jantung kota Jakarta dengan akses langsung MRT/KRL dan pencahayaan bebas silau.',
  ),
  Court(
    id: 'c56',
    name: 'Tropical Oasis Court 4',
    venue: 'Bali Social Club Canggu',
    area: 'Canggu, Badung',
    rating: 4.8,
    pricePerHour: 290,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_bali_social_club.jpg',
    facilities: ['Cold Plunge Ice Bath', 'Sauna Kayu Jati', 'Organic Cafe & Smoothies', 'Tropical Garden Vibe', 'Shower Outdoor', 'Komunitas Internasional'],
    description: 'Sanctuary padel dengan sentuhan tropis Canggu, recovery cold plunge pool, sauna kayu jati, dan cafe organik pasca tanding.',
  ),
  Court(
    id: 'c57',
    name: 'Cliffside Pro Arena 4',
    venue: 'Monster Padel Uluwatu',
    area: 'Uluwatu, Badung',
    rating: 4.7,
    pricePerHour: 280,
    indoor: false,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_monster_uluwatu.jpg',
    facilities: ['Cliffside Ocean Breeze', 'Anti-Slip FIP Turf', 'Sunset Viewing Lounge', 'Cocktail & Healthy Bar', 'Sewa Sepatu & Raket', 'Pro Sparring'],
    description: 'Lapangan outdoor spektakuler di atas tebing Uluwatu dengan semilir angin laut dan karpet anti-slip standar FIP.',
  ),
  Court(
    id: 'c58',
    name: 'Shortcut Jungle Court 4',
    venue: 'Jungle Padel Canggu',
    area: 'Pererenan, Badung',
    rating: 4.8,
    pricePerHour: 270,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_jungle_canggu.jpg',
    facilities: ['Green Ricefield View', '4 Lapangan Semi-Outdoor', 'Komunitas Mabar Harian', 'Cafe & Fresh Coconut', 'Locker Room', 'Pet Friendly'],
    description: 'Pionir klub padel pertama di Bali dengan pemandangan sawah alami dan suasana komunitas mabar yang guyub.',
  ),
  Court(
    id: 'c59',
    name: 'High-Tech Glass Arena 4',
    venue: 'SPACE PADEL PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.8,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_space_pik2.webp',
    facilities: ['Smart Instant Replay', 'Digital Scoreboard', 'VIP Player Lounge', 'Loker Elektronik', 'Shower Bertekanan Tinggi', 'Parkir Basement'],
    description: 'Arena padel futuristik dilengkapi smart camera untuk merekam poin terbaik dan replay gerakan smash secara otomatis.',
  ),
  Court(
    id: 'c60',
    name: 'Boutique Glass Court 4',
    venue: 'Maison de Padel',
    area: 'Kebon Jeruk, Jakarta',
    rating: 5.0,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_maison_de_padel.webp',
    facilities: ['Boutique Private Courts', 'FIP Certified Coaching', 'Artisan Coffee Bar', 'Shower Air Panas', 'WiFi High-Speed', 'Private Event Booking'],
    description: 'Klub padel boutique di Jakarta Barat dengan suasana privat eksklusif dan bimbingan pelatih bersertifikasi FIP.',
  ),
  Court(
    id: 'c61',
    name: 'Urban Lifestyle Court 4',
    venue: 'Artepola Padel Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.7,
    pricePerHour: 200,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_artepola_kemang.webp',
    facilities: ['Lifestyle Bistro Cafe', 'Full Air Conditioner', 'DJ Night Sessions', 'Locker Room Luas', 'Sewa Raket Head & Nox', 'Parkir Valet'],
    description: 'Tempat favorit komunitas urban lifestyle Jakarta Selatan untuk bermain padel dan hangout sore di bistro artisan.',
  ),
  Court(
    id: 'c62',
    name: 'Industrial High-Loft 4',
    venue: 'Warehaus Padel Tangerang',
    area: 'Alam Sutera, Tangerang',
    rating: 4.9,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_warehaus_tangerang.webp',
    facilities: ['High Ceiling 11 Meter', 'Sirkulasi Udara Natural', 'Zero-Glare LED Lighting', 'Pro Shop Terlengkap', 'Musholla & Shower', 'Resto & Cafe'],
    description: 'Desain open-hall warehouse berplafon setinggi 11 meter dengan sirkulasi udara optimal dan zero-glare lighting.',
  ),
  Court(
    id: 'c63',
    name: 'Zenith Glass Court 4',
    venue: 'Aman Padel Denpasar',
    area: 'Denpasar Barat, Denpasar',
    rating: 4.4,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_aman_denpasar.jpg',
    facilities: ['Pusat Kota Denpasar', 'Indoor Anti-Hujan', 'Sewa Raket Babolat', 'Locker Room', 'Area Nonton Mezzanine', 'Minuman Isotonik Dingin'],
    description: 'Padel court modern di pusat kota Denpasar dengan sewa raket premium, toko perlengkapan, dan ruang ganti bersih.',
  ),
  Court(
    id: 'c64',
    name: 'Sanctuary Valley Court 4',
    venue: 'TAO Padel Academy Ubud',
    area: 'Ubud, Gianyar',
    rating: 4.6,
    pricePerHour: 230,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_tao_ubud.jpg',
    facilities: ['Pemandangan Lembah Ubud', 'Akademi Pelatihan FIP', 'Meditation & Yoga Deck', 'Organic Healthy Bowls', 'Shower Outdoor', 'Klinik Fisioterapi'],
    description: 'Akademi padel di tengah ketenangan alam Ubud dengan program pelatihan intensif pemula hingga atlet pro.',
  ),
  Court(
    id: 'c65',
    name: 'Signature Pink Indoor Court 5',
    venue: 'Padel Pro Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.8,
    pricePerHour: 220,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_padel_pro_kemang.jpg',
    facilities: ['Karpet Pink WPT', 'Full AC & High Ceiling', 'Matchmaking Service', 'Padel Cafe', 'Shower Air Panas', 'Parkir Luas'],
    description: 'Klub padel indoor premier di Kemang dengan 6 lapangan ber-AC, karpet pink ikonik, fasilitas cafe, dan pro shop terlengkap.',
  ),
  Court(
    id: 'c66',
    name: 'Menteng Panoramic Glass 5',
    venue: 'Social Padel House Menteng',
    area: 'Menteng, Jakarta',
    rating: 4.9,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_social_menteng.jpg',
    facilities: ['5 Lapangan Indoor', 'Lounge Bar & Cafe', 'Kaca Panoramic 12mm', 'Mix-ins & Social Play', 'Pro Shop', 'WiFi Cepat'],
    description: '5 lapangan padel indoor modern di pusat Jakarta dengan lounge bar berkelas, ruang ganti mewah, dan komunitas aktif.',
  ),
  Court(
    id: 'c67',
    name: 'Center Glass Court 5',
    venue: 'Social Padel House Setiabudi',
    area: 'Setiabudi, Jakarta',
    rating: 4.9,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_social_setiabudi.jpg',
    facilities: ['Kaca Tempered 12mm', 'LED 600 Lux Anti-Silau', 'Locker Room VIP', 'Cold Plunge', 'Kafe & Juice Bar', 'Valet Parking'],
    description: 'Lapangan panoramic kaca tempered 12mm anti-shatter di segitiga emas Setiabudi dengan pencahayaan LED 600 Lux turnamen.',
  ),
  Court(
    id: 'c68',
    name: 'Beachfront Sunset Court 5',
    venue: 'HPC Atlas Beach Club',
    area: 'Canggu, Badung',
    rating: 4.8,
    pricePerHour: 340,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_hpc_atlas_bali.jpg',
    facilities: ['Beachfront Ocean View', 'Floodlit Night Play', 'Akses Beach Club', 'Changing Rooms & Shower', 'Towel Service', 'Sunset Lounge'],
    description: 'Main padel outdoor tepat di tepi Pantai Berawa Canggu dengan suasana sunset spektakuler dan akses langsung ke beach club.',
  ),
  Court(
    id: 'c69',
    name: 'Grand Arena Hall 5',
    venue: 'Rekket Space Padel Hall',
    area: 'BSD, Tangerang',
    rating: 4.6,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_rekket_bsd.jpg',
    facilities: ['Run-off Space 3 Meter', 'Karpet Mondo Supercourt', 'Pro Coaching Clinic', 'Kids Padel Clinic', 'Tribun Penonton', 'Parkir 100+ Mobil'],
    description: 'Padel hall terbesar di kawasan BSD dengan 3 meter run-off space, karpet Mondo, dan program klinik pembinaan atlet.',
  ),
  Court(
    id: 'c70',
    name: 'Verde Championship Court 5',
    venue: 'Verde Sports Hub PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.8,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_verde_pik2.jpg',
    facilities: ['World Padel Tour Specs', 'Clubhouse & Restaurant', 'Smart Replay Camera', 'Locker Room Mewah', 'Toko Raket Bullpadel', 'Outdoor Deck'],
    description: 'Sports hub prestisius di kawasan PIK 2 dengan lapangan berstandar World Padel Tour dan fasilitas olahraga terpadu.',
  ),
  Court(
    id: 'c71',
    name: 'Monas Panoramic Arena 5',
    venue: 'Nine Padel Monas',
    area: 'Gambir, Jakarta',
    rating: 4.9,
    pricePerHour: 230,
    indoor: true,
    gradient: [Color(0xFF5B2AA8), Color(0xFF8046D8)],
    image: 'assets/images/court_nine_monas.jpg',
    facilities: ['Akses MRT & KRL', 'Zero-Glare LED', 'Sewa Raket Babolat', 'Cafe & Healthy Bar', 'Shower Air Panas', 'Musholla Nyaman'],
    description: 'Lapangan padel strategis di jantung kota Jakarta dengan akses langsung MRT/KRL dan pencahayaan bebas silau.',
  ),
  Court(
    id: 'c72',
    name: 'Tropical Oasis Court 5',
    venue: 'Bali Social Club Canggu',
    area: 'Canggu, Badung',
    rating: 4.7,
    pricePerHour: 290,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_bali_social_club.jpg',
    facilities: ['Cold Plunge Ice Bath', 'Sauna Kayu Jati', 'Organic Cafe & Smoothies', 'Tropical Garden Vibe', 'Shower Outdoor', 'Komunitas Internasional'],
    description: 'Sanctuary padel dengan sentuhan tropis Canggu, recovery cold plunge pool, sauna kayu jati, dan cafe organik pasca tanding.',
  ),
  Court(
    id: 'c73',
    name: 'Cliffside Pro Arena 5',
    venue: 'Monster Padel Uluwatu',
    area: 'Uluwatu, Badung',
    rating: 4.6,
    pricePerHour: 280,
    indoor: false,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_monster_uluwatu.jpg',
    facilities: ['Cliffside Ocean Breeze', 'Anti-Slip FIP Turf', 'Sunset Viewing Lounge', 'Cocktail & Healthy Bar', 'Sewa Sepatu & Raket', 'Pro Sparring'],
    description: 'Lapangan outdoor spektakuler di atas tebing Uluwatu dengan semilir angin laut dan karpet anti-slip standar FIP.',
  ),
  Court(
    id: 'c74',
    name: 'Shortcut Jungle Court 5',
    venue: 'Jungle Padel Canggu',
    area: 'Pererenan, Badung',
    rating: 4.7,
    pricePerHour: 270,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_jungle_canggu.jpg',
    facilities: ['Green Ricefield View', '4 Lapangan Semi-Outdoor', 'Komunitas Mabar Harian', 'Cafe & Fresh Coconut', 'Locker Room', 'Pet Friendly'],
    description: 'Pionir klub padel pertama di Bali dengan pemandangan sawah alami dan suasana komunitas mabar yang guyub.',
  ),
  Court(
    id: 'c75',
    name: 'High-Tech Glass Arena 5',
    venue: 'SPACE PADEL PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 5.0,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_space_pik2.webp',
    facilities: ['Smart Instant Replay', 'Digital Scoreboard', 'VIP Player Lounge', 'Loker Elektronik', 'Shower Bertekanan Tinggi', 'Parkir Basement'],
    description: 'Arena padel futuristik dilengkapi smart camera untuk merekam poin terbaik dan replay gerakan smash secara otomatis.',
  ),
  Court(
    id: 'c76',
    name: 'Boutique Glass Court 5',
    venue: 'Maison de Padel',
    area: 'Kebon Jeruk, Jakarta',
    rating: 5.0,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_maison_de_padel.webp',
    facilities: ['Boutique Private Courts', 'FIP Certified Coaching', 'Artisan Coffee Bar', 'Shower Air Panas', 'WiFi High-Speed', 'Private Event Booking'],
    description: 'Klub padel boutique di Jakarta Barat dengan suasana privat eksklusif dan bimbingan pelatih bersertifikasi FIP.',
  ),
  Court(
    id: 'c77',
    name: 'Urban Lifestyle Court 5',
    venue: 'Artepola Padel Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.6,
    pricePerHour: 200,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_artepola_kemang.webp',
    facilities: ['Lifestyle Bistro Cafe', 'Full Air Conditioner', 'DJ Night Sessions', 'Locker Room Luas', 'Sewa Raket Head & Nox', 'Parkir Valet'],
    description: 'Tempat favorit komunitas urban lifestyle Jakarta Selatan untuk bermain padel dan hangout sore di bistro artisan.',
  ),
  Court(
    id: 'c78',
    name: 'Industrial High-Loft 5',
    venue: 'Warehaus Padel Tangerang',
    area: 'Alam Sutera, Tangerang',
    rating: 4.8,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_warehaus_tangerang.webp',
    facilities: ['High Ceiling 11 Meter', 'Sirkulasi Udara Natural', 'Zero-Glare LED Lighting', 'Pro Shop Terlengkap', 'Musholla & Shower', 'Resto & Cafe'],
    description: 'Desain open-hall warehouse berplafon setinggi 11 meter dengan sirkulasi udara optimal dan zero-glare lighting.',
  ),
  Court(
    id: 'c79',
    name: 'Zenith Glass Court 5',
    venue: 'Aman Padel Denpasar',
    area: 'Denpasar Barat, Denpasar',
    rating: 4.4,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_aman_denpasar.jpg',
    facilities: ['Pusat Kota Denpasar', 'Indoor Anti-Hujan', 'Sewa Raket Babolat', 'Locker Room', 'Area Nonton Mezzanine', 'Minuman Isotonik Dingin'],
    description: 'Padel court modern di pusat kota Denpasar dengan sewa raket premium, toko perlengkapan, dan ruang ganti bersih.',
  ),
  Court(
    id: 'c80',
    name: 'Sanctuary Valley Court 5',
    venue: 'TAO Padel Academy Ubud',
    area: 'Ubud, Gianyar',
    rating: 4.8,
    pricePerHour: 230,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_tao_ubud.jpg',
    facilities: ['Pemandangan Lembah Ubud', 'Akademi Pelatihan FIP', 'Meditation & Yoga Deck', 'Organic Healthy Bowls', 'Shower Outdoor', 'Klinik Fisioterapi'],
    description: 'Akademi padel di tengah ketenangan alam Ubud dengan program pelatihan intensif pemula hingga atlet pro.',
  ),
  Court(
    id: 'c81',
    name: 'Signature Pink Indoor Court 6',
    venue: 'Padel Pro Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.8,
    pricePerHour: 220,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_padel_pro_kemang.jpg',
    facilities: ['Karpet Pink WPT', 'Full AC & High Ceiling', 'Matchmaking Service', 'Padel Cafe', 'Shower Air Panas', 'Parkir Luas'],
    description: 'Klub padel indoor premier di Kemang dengan 6 lapangan ber-AC, karpet pink ikonik, fasilitas cafe, dan pro shop terlengkap.',
  ),
  Court(
    id: 'c82',
    name: 'Menteng Panoramic Glass 6',
    venue: 'Social Padel House Menteng',
    area: 'Menteng, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_social_menteng.jpg',
    facilities: ['5 Lapangan Indoor', 'Lounge Bar & Cafe', 'Kaca Panoramic 12mm', 'Mix-ins & Social Play', 'Pro Shop', 'WiFi Cepat'],
    description: '5 lapangan padel indoor modern di pusat Jakarta dengan lounge bar berkelas, ruang ganti mewah, dan komunitas aktif.',
  ),
  Court(
    id: 'c83',
    name: 'Center Glass Court 6',
    venue: 'Social Padel House Setiabudi',
    area: 'Setiabudi, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_social_setiabudi.jpg',
    facilities: ['Kaca Tempered 12mm', 'LED 600 Lux Anti-Silau', 'Locker Room VIP', 'Cold Plunge', 'Kafe & Juice Bar', 'Valet Parking'],
    description: 'Lapangan panoramic kaca tempered 12mm anti-shatter di segitiga emas Setiabudi dengan pencahayaan LED 600 Lux turnamen.',
  ),
  Court(
    id: 'c84',
    name: 'Beachfront Sunset Court 6',
    venue: 'HPC Atlas Beach Club',
    area: 'Canggu, Badung',
    rating: 4.7,
    pricePerHour: 340,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_hpc_atlas_bali.jpg',
    facilities: ['Beachfront Ocean View', 'Floodlit Night Play', 'Akses Beach Club', 'Changing Rooms & Shower', 'Towel Service', 'Sunset Lounge'],
    description: 'Main padel outdoor tepat di tepi Pantai Berawa Canggu dengan suasana sunset spektakuler dan akses langsung ke beach club.',
  ),
  Court(
    id: 'c85',
    name: 'Grand Arena Hall 6',
    venue: 'Rekket Space Padel Hall',
    area: 'BSD, Tangerang',
    rating: 4.8,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_rekket_bsd.jpg',
    facilities: ['Run-off Space 3 Meter', 'Karpet Mondo Supercourt', 'Pro Coaching Clinic', 'Kids Padel Clinic', 'Tribun Penonton', 'Parkir 100+ Mobil'],
    description: 'Padel hall terbesar di kawasan BSD dengan 3 meter run-off space, karpet Mondo, dan program klinik pembinaan atlet.',
  ),
  Court(
    id: 'c86',
    name: 'Verde Championship Court 6',
    venue: 'Verde Sports Hub PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 4.8,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_verde_pik2.jpg',
    facilities: ['World Padel Tour Specs', 'Clubhouse & Restaurant', 'Smart Replay Camera', 'Locker Room Mewah', 'Toko Raket Bullpadel', 'Outdoor Deck'],
    description: 'Sports hub prestisius di kawasan PIK 2 dengan lapangan berstandar World Padel Tour dan fasilitas olahraga terpadu.',
  ),
  Court(
    id: 'c87',
    name: 'Monas Panoramic Arena 6',
    venue: 'Nine Padel Monas',
    area: 'Gambir, Jakarta',
    rating: 4.8,
    pricePerHour: 230,
    indoor: true,
    gradient: [Color(0xFF5B2AA8), Color(0xFF8046D8)],
    image: 'assets/images/court_nine_monas.jpg',
    facilities: ['Akses MRT & KRL', 'Zero-Glare LED', 'Sewa Raket Babolat', 'Cafe & Healthy Bar', 'Shower Air Panas', 'Musholla Nyaman'],
    description: 'Lapangan padel strategis di jantung kota Jakarta dengan akses langsung MRT/KRL dan pencahayaan bebas silau.',
  ),
  Court(
    id: 'c88',
    name: 'Tropical Oasis Court 6',
    venue: 'Bali Social Club Canggu',
    area: 'Canggu, Badung',
    rating: 4.6,
    pricePerHour: 290,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_bali_social_club.jpg',
    facilities: ['Cold Plunge Ice Bath', 'Sauna Kayu Jati', 'Organic Cafe & Smoothies', 'Tropical Garden Vibe', 'Shower Outdoor', 'Komunitas Internasional'],
    description: 'Sanctuary padel dengan sentuhan tropis Canggu, recovery cold plunge pool, sauna kayu jati, dan cafe organik pasca tanding.',
  ),
  Court(
    id: 'c89',
    name: 'Cliffside Pro Arena 6',
    venue: 'Monster Padel Uluwatu',
    area: 'Uluwatu, Badung',
    rating: 4.6,
    pricePerHour: 280,
    indoor: false,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_monster_uluwatu.jpg',
    facilities: ['Cliffside Ocean Breeze', 'Anti-Slip FIP Turf', 'Sunset Viewing Lounge', 'Cocktail & Healthy Bar', 'Sewa Sepatu & Raket', 'Pro Sparring'],
    description: 'Lapangan outdoor spektakuler di atas tebing Uluwatu dengan semilir angin laut dan karpet anti-slip standar FIP.',
  ),
  Court(
    id: 'c90',
    name: 'Shortcut Jungle Court 6',
    venue: 'Jungle Padel Canggu',
    area: 'Pererenan, Badung',
    rating: 4.9,
    pricePerHour: 270,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_jungle_canggu.jpg',
    facilities: ['Green Ricefield View', '4 Lapangan Semi-Outdoor', 'Komunitas Mabar Harian', 'Cafe & Fresh Coconut', 'Locker Room', 'Pet Friendly'],
    description: 'Pionir klub padel pertama di Bali dengan pemandangan sawah alami dan suasana komunitas mabar yang guyub.',
  ),
  Court(
    id: 'c91',
    name: 'High-Tech Glass Arena 6',
    venue: 'SPACE PADEL PIK 2',
    area: 'PIK 2, Tangerang',
    rating: 5.0,
    pricePerHour: 240,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_space_pik2.webp',
    facilities: ['Smart Instant Replay', 'Digital Scoreboard', 'VIP Player Lounge', 'Loker Elektronik', 'Shower Bertekanan Tinggi', 'Parkir Basement'],
    description: 'Arena padel futuristik dilengkapi smart camera untuk merekam poin terbaik dan replay gerakan smash secara otomatis.',
  ),
  Court(
    id: 'c92',
    name: 'Boutique Glass Court 6',
    venue: 'Maison de Padel',
    area: 'Kebon Jeruk, Jakarta',
    rating: 4.9,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_maison_de_padel.webp',
    facilities: ['Boutique Private Courts', 'FIP Certified Coaching', 'Artisan Coffee Bar', 'Shower Air Panas', 'WiFi High-Speed', 'Private Event Booking'],
    description: 'Klub padel boutique di Jakarta Barat dengan suasana privat eksklusif dan bimbingan pelatih bersertifikasi FIP.',
  ),
  Court(
    id: 'c93',
    name: 'Urban Lifestyle Court 6',
    venue: 'Artepola Padel Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.5,
    pricePerHour: 200,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_artepola_kemang.webp',
    facilities: ['Lifestyle Bistro Cafe', 'Full Air Conditioner', 'DJ Night Sessions', 'Locker Room Luas', 'Sewa Raket Head & Nox', 'Parkir Valet'],
    description: 'Tempat favorit komunitas urban lifestyle Jakarta Selatan untuk bermain padel dan hangout sore di bistro artisan.',
  ),
  Court(
    id: 'c94',
    name: 'Industrial High-Loft 6',
    venue: 'Warehaus Padel Tangerang',
    area: 'Alam Sutera, Tangerang',
    rating: 4.8,
    pricePerHour: 185,
    indoor: true,
    gradient: [Color(0xFF0E7C66), Color(0xFF17A687)],
    image: 'assets/images/court_warehaus_tangerang.webp',
    facilities: ['High Ceiling 11 Meter', 'Sirkulasi Udara Natural', 'Zero-Glare LED Lighting', 'Pro Shop Terlengkap', 'Musholla & Shower', 'Resto & Cafe'],
    description: 'Desain open-hall warehouse berplafon setinggi 11 meter dengan sirkulasi udara optimal dan zero-glare lighting.',
  ),
  Court(
    id: 'c95',
    name: 'Zenith Glass Court 6',
    venue: 'Aman Padel Denpasar',
    area: 'Denpasar Barat, Denpasar',
    rating: 4.6,
    pricePerHour: 180,
    indoor: true,
    gradient: [Color(0xFF0B6E99), Color(0xFF1A9FD1)],
    image: 'assets/images/court_aman_denpasar.jpg',
    facilities: ['Pusat Kota Denpasar', 'Indoor Anti-Hujan', 'Sewa Raket Babolat', 'Locker Room', 'Area Nonton Mezzanine', 'Minuman Isotonik Dingin'],
    description: 'Padel court modern di pusat kota Denpasar dengan sewa raket premium, toko perlengkapan, dan ruang ganti bersih.',
  ),
  Court(
    id: 'c96',
    name: 'Sanctuary Valley Court 6',
    venue: 'TAO Padel Academy Ubud',
    area: 'Ubud, Gianyar',
    rating: 4.8,
    pricePerHour: 230,
    indoor: false,
    gradient: [Color(0xFF1F6F3C), Color(0xFF2FA85C)],
    image: 'assets/images/court_tao_ubud.jpg',
    facilities: ['Pemandangan Lembah Ubud', 'Akademi Pelatihan FIP', 'Meditation & Yoga Deck', 'Organic Healthy Bowls', 'Shower Outdoor', 'Klinik Fisioterapi'],
    description: 'Akademi padel di tengah ketenangan alam Ubud dengan program pelatihan intensif pemula hingga atlet pro.',
  ),
  Court(
    id: 'c97',
    name: 'Signature Pink Indoor Court 7',
    venue: 'Padel Pro Kemang',
    area: 'Kemang, Jakarta',
    rating: 4.7,
    pricePerHour: 220,
    indoor: true,
    gradient: [Color(0xFFB03060), Color(0xFFE2568C)],
    image: 'assets/images/court_padel_pro_kemang.jpg',
    facilities: ['Karpet Pink WPT', 'Full AC & High Ceiling', 'Matchmaking Service', 'Padel Cafe', 'Shower Air Panas', 'Parkir Luas'],
    description: 'Klub padel indoor premier di Kemang dengan 6 lapangan ber-AC, karpet pink ikonik, fasilitas cafe, dan pro shop terlengkap.',
  ),
  Court(
    id: 'c98',
    name: 'Menteng Panoramic Glass 7',
    venue: 'Social Padel House Menteng',
    area: 'Menteng, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF2334DB), Color(0xFF4756F0)],
    image: 'assets/images/court_social_menteng.jpg',
    facilities: ['5 Lapangan Indoor', 'Lounge Bar & Cafe', 'Kaca Panoramic 12mm', 'Mix-ins & Social Play', 'Pro Shop', 'WiFi Cepat'],
    description: '5 lapangan padel indoor modern di pusat Jakarta dengan lounge bar berkelas, ruang ganti mewah, dan komunitas aktif.',
  ),
  Court(
    id: 'c99',
    name: 'Center Glass Court 7',
    venue: 'Social Padel House Setiabudi',
    area: 'Setiabudi, Jakarta',
    rating: 4.8,
    pricePerHour: 260,
    indoor: true,
    gradient: [Color(0xFF151C4E), Color(0xFF2B3A86)],
    image: 'assets/images/court_social_setiabudi.jpg',
    facilities: ['Kaca Tempered 12mm', 'LED 600 Lux Anti-Silau', 'Locker Room VIP', 'Cold Plunge', 'Kafe & Juice Bar', 'Valet Parking'],
    description: 'Lapangan panoramic kaca tempered 12mm anti-shatter di segitiga emas Setiabudi dengan pencahayaan LED 600 Lux turnamen.',
  ),
  Court(
    id: 'c100',
    name: 'Beachfront Sunset Court 7',
    venue: 'HPC Atlas Beach Club',
    area: 'Canggu, Badung',
    rating: 4.9,
    pricePerHour: 340,
    indoor: false,
    gradient: [Color(0xFFE05A2B), Color(0xFFF08A3A)],
    image: 'assets/images/court_hpc_atlas_bali.jpg',
    facilities: ['Beachfront Ocean View', 'Floodlit Night Play', 'Akses Beach Club', 'Changing Rooms & Shower', 'Towel Service', 'Sunset Lounge'],
    description: 'Main padel outdoor tepat di tepi Pantai Berawa Canggu dengan suasana sunset spektakuler dan akses langsung ke beach club.',
  ),
];

/// Live catalog: starts as the offline fallback, replaced by CatalogStore.
List<Court> courts = fallbackCourts;

/// 08:00 - 22:00 hourly slots.
final List<String> allSlots = List.generate(
  14,
  (i) => '${(8 + i).toString().padLeft(2, '0')}:00',
);

// ---------- Leaderboard ----------
class Player {
  final String id;
  final String name;
  final String username;
  final int points;
  final int wins;
  final int matches;
  final bool isMe;
  final int rank;
  final String? photoUrl;
  const Player({
    required this.id,
    required this.name,
    this.username = '',
    required this.points,
    required this.wins,
    required this.matches,
    this.isMe = false,
    this.rank = 0,
    this.photoUrl,
  });

  factory Player.fromJson(Map<String, dynamic> m) => Player(
        id: '${m['id']}',
        name: (m['name'] as String?) ?? '',
        username: (m['username'] as String?) ?? '',
        points: (m['points'] as num?)?.toInt() ?? 0,
        wins: (m['wins'] as num?)?.toInt() ?? 0,
        matches: (m['matches'] as num?)?.toInt() ?? 0,
        isMe: m['isMe'] == true,
        rank: (m['rank'] as num?)?.toInt() ?? 0,
        photoUrl: m['photoUrl'] as String?,
      );

  String get handle => username.isNotEmpty
      ? '@$username'
      : '@${name.toLowerCase().replaceAll(' ', '')}';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return (parts.first.length >= 2 ? parts.first.substring(0, 2) : parts.first)
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ---------- Achievements ----------
class Achievement {
  final String key;
  final String title;
  final String desc;
  final IconData icon;
  final int progress; // current
  final int target;
  const Achievement({
    this.key = '',
    required this.title,
    required this.desc,
    required this.icon,
    required this.progress,
    required this.target,
  });

  bool get unlocked => progress >= target;
  double get ratio => (progress / target).clamp(0.0, 1.0);

  /// Maps a server achievement (`key`) to the app's icon set.
  factory Achievement.fromJson(Map<String, dynamic> m) => Achievement(
        key: '${m['key']}',
        title: (m['title'] as String?) ?? '',
        desc: (m['desc'] as String?) ?? '',
        icon: achievementIcons['${m['key']}'] ?? LucideIcons.award,
        progress: (m['progress'] as num?)?.toInt() ?? 0,
        target: ((m['target'] as num?)?.toInt() ?? 1).clamp(1, 1 << 30),
      );
}

const achievementIcons = <String, IconData>{
  'first_serve': kBallIcon,
  'rajin_main': LucideIcons.flame,
  'early_bird': LucideIcons.sun,
  'globetrotter': LucideIcons.globe,
  'win_streak': LucideIcons.zap,
  'centurion': LucideIcons.timer,
  'top3': LucideIcons.trophy,
  'ace_master': LucideIcons.medal,
};

/// Zero-progress placeholders shown until /achievements loads (or logged out).
const achievements = <Achievement>[
  Achievement(key: 'first_serve', title: 'First Serve', desc: 'Selesaikan booking pertama', icon: kBallIcon, progress: 0, target: 1),
  Achievement(key: 'rajin_main', title: 'Rajin Main', desc: 'Main 10 kali', icon: LucideIcons.flame, progress: 0, target: 10),
  Achievement(key: 'early_bird', title: 'Early Bird', desc: 'Booking slot pagi 5x', icon: LucideIcons.sun, progress: 0, target: 5),
  Achievement(key: 'globetrotter', title: 'Globetrotter', desc: 'Main di 4 venue berbeda', icon: LucideIcons.globe, progress: 0, target: 4),
  Achievement(key: 'win_streak', title: 'Win Streak', desc: 'Menang 5 kali', icon: LucideIcons.zap, progress: 0, target: 5),
  Achievement(key: 'centurion', title: 'Centurion', desc: 'Capai 100 jam main', icon: LucideIcons.timer, progress: 0, target: 100),
  Achievement(key: 'top3', title: 'Top 3', desc: 'Masuk 3 besar leaderboard', icon: LucideIcons.trophy, progress: 0, target: 1),
  Achievement(key: 'ace_master', title: 'Ace Master', desc: 'Kumpulkan 3000 poin', icon: LucideIcons.medal, progress: 0, target: 3000),
];

// ---------- Vouchers & Promo ----------
class Voucher {
  final String code;
  final String title;
  final String description;
  final int discountAmount; // in thousands IDR (e.g. 25 = Rp25k)
  final int minSpend; // in thousands IDR
  final double? percentage; // e.g. 0.20 for 20%
  final int? maxDiscount;
  const Voucher({
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    this.minSpend = 0,
    this.percentage,
    this.maxDiscount,
  });

  factory Voucher.fromJson(Map<String, dynamic> m) => Voucher(
        code: '${m['code']}',
        title: (m['title'] as String?) ?? '',
        description: (m['description'] as String?) ?? '',
        discountAmount: (m['discountAmount'] as num?)?.toInt() ?? 0,
        minSpend: (m['minSpend'] as num?)?.toInt() ?? 0,
        percentage: (m['percentage'] as num?)?.toDouble(),
        maxDiscount: (m['maxDiscount'] as num?)?.toInt(),
      );

  /// Display estimate; the server is authoritative (POST /vouchers/validate).
  int calculateDiscount(int priceInThousands) {
    if (priceInThousands < minSpend) return 0;
    if (percentage != null && percentage! > 0) {
      final disc = (priceInThousands * percentage!).round();
      if (maxDiscount != null && maxDiscount! > 0 && disc > maxDiscount!) {
        return maxDiscount!;
      }
      return disc;
    }
    return discountAmount.clamp(0, priceInThousands);
  }
}

// ---------- Open Matches (Mabar Padel / Community) ----------
class OpenMatch {
  final String id;
  final Court court;
  final String dateString;
  final String time; // e.g. "19:00 - 21:00"
  final String title;
  final String hostName;
  final String hostId;
  final String skillLevel; // 'Semua Level', 'Menengah (Intermediate)', 'Mahir (Pro)'
  final int currentPlayers;
  final int maxPlayers;
  final int pricePerPlayer; // in thousands IDR
  final bool isJoined;
  final List<String> players;
  const OpenMatch({
    required this.id,
    required this.court,
    required this.dateString,
    required this.time,
    required this.title,
    required this.hostName,
    this.hostId = '',
    required this.skillLevel,
    required this.currentPlayers,
    this.maxPlayers = 4,
    required this.pricePerPlayer,
    this.isJoined = false,
    this.players = const [],
  });

  factory OpenMatch.fromJson(Map<String, dynamic> m) {
    final cj = m['court'];
    final court = cj is Map<String, dynamic>
        ? Court.fromJson(cj)
        : courts.firstWhere((c) => c.id == m['courtId'], orElse: () => courts.first);
    return OpenMatch(
      id: '${m['id']}',
      court: court,
      dateString: (m['dateString'] as String?) ?? '',
      time: (m['time'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      hostName: (m['hostName'] as String?) ?? '',
      hostId: '${m['hostId'] ?? ''}',
      skillLevel: (m['skillLevel'] as String?) ?? 'Semua Level',
      currentPlayers: (m['currentPlayers'] as num?)?.toInt() ?? 0,
      maxPlayers: (m['maxPlayers'] as num?)?.toInt() ?? 4,
      pricePerPlayer: (m['pricePerPlayer'] as num?)?.toInt() ?? 0,
      isJoined: m['isJoined'] == true,
      players: (m['players'] as List?)?.map((e) => '$e').toList() ?? const [],
    );
  }

  OpenMatch copyWith({
    int? currentPlayers,
    bool? isJoined,
  }) {
    return OpenMatch(
      id: id,
      court: court,
      dateString: dateString,
      time: time,
      title: title,
      hostName: hostName,
      hostId: hostId,
      skillLevel: skillLevel,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      maxPlayers: maxPlayers,
      pricePerPlayer: pricePerPlayer,
      isJoined: isJoined ?? this.isJoined,
      players: players,
    );
  }
}

// ---------- Reviews & Ratings ----------
class CourtReview {
  final String id;
  final String courtId;
  final String userName;
  final double rating;
  final String comment;
  final String date;
  final String skillLevel;
  const CourtReview({
    required this.id,
    required this.courtId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    required this.skillLevel,
  });

  factory CourtReview.fromJson(Map<String, dynamic> m) => CourtReview(
        id: '${m['id']}',
        courtId: '${m['courtId']}',
        userName: (m['userName'] as String?) ?? 'Pemain',
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        comment: (m['comment'] as String?) ?? '',
        date: relativeDate(m['createdAt'] as String?),
        skillLevel: ((m['skillLevel'] as String?) ?? '').split(' ').first,
      );
}

List<String> _strList(dynamic v, String fallback) {
  final l = (v as List?)?.map((e) => '$e').toList() ?? <String>[];
  return l.isEmpty ? [fallback] : l;
}

/// "Hari ini", "3 hari lalu", ... from an ISO timestamp.
String relativeDate(String? iso) {
  final t = DateTime.tryParse(iso ?? '')?.toLocal();
  if (t == null) return '';
  final days = DateTime.now().difference(t).inDays;
  if (days <= 0) return 'Hari ini';
  if (days == 1) return 'Kemarin';
  if (days < 7) return '$days hari lalu';
  if (days < 30) return '${days ~/ 7} minggu lalu';
  return '${days ~/ 30} bulan lalu';
}

// ---------- Perlengkapan & Add-Ons ----------
class EquipmentAddOn {
  final String id;
  final String name;
  final int price; // in thousands (e.g. 30 -> Rp30.000)
  final String description;
  final IconData icon;

  const EquipmentAddOn({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.icon,
  });
}

const equipmentAddOns = <EquipmentAddOn>[
  EquipmentAddOn(
    id: 'racket',
    name: 'Sewa Raket Bullpadel Pro',
    price: 30,
    description: 'Sweet-spot lebar & grip anti-slip',
    icon: kRacketIcon,
  ),
  EquipmentAddOn(
    id: 'balls',
    name: '1 Can Bola Baru (3 Pcs)',
    price: 75,
    description: 'Bola padel bertekanan standar turnamen',
    icon: kBallIcon,
  ),
  EquipmentAddOn(
    id: 'refreshment',
    name: 'Paket Handuk & 2 Air Mineral',
    price: 15,
    description: 'Handuk katun bersih + air mineral dingin',
    icon: LucideIcons.droplet,
  ),
];

// ---------- Pelatih & Sparring Partner ----------
class Coach {
  final String id;
  final String name;
  final String title;
  final double rating;
  final int reviewsCount;
  final int ratePerHour; // in thousands (e.g. 250 -> Rp250.000)
  final String experience;
  final String image;
  final List<String> specialties;
  final List<String> availableVenues;
  final String bio;

  const Coach({
    required this.id,
    required this.name,
    required this.title,
    required this.rating,
    required this.reviewsCount,
    required this.ratePerHour,
    required this.experience,
    required this.image,
    required this.specialties,
    required this.availableVenues,
    required this.bio,
  });

  factory Coach.fromJson(Map<String, dynamic> m) {
    final img = (m['image'] as String?) ?? '';
    final url = (m['imageUrl'] as String?) ?? '';
    return Coach(
      id: '${m['id']}',
      name: (m['name'] as String?) ?? '',
      title: (m['title'] as String?) ?? '',
      rating: (m['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (m['reviewsCount'] as num?)?.toInt() ?? 0,
      ratePerHour: (m['ratePerHour'] as num?)?.toInt() ?? 0,
      experience: (m['experience'] as String?) ?? '',
      image: img.startsWith('assets/') ? img : (url.isNotEmpty ? url : img),
      specialties: _strList(m['specialties'], 'Umum'),
      availableVenues: _strList(m['availableVenues'], 'Lapangan Ace Padel'),
      bio: (m['bio'] as String?) ?? '',
    );
  }
}

const initialCoaches = <Coach>[
  Coach(
    id: 'coach1',
    name: 'Edu Altimires Ros',
    title: 'Head Coach • FIP Certified Level 2',
    rating: 4.98,
    reviewsCount: 184,
    ratePerHour: 290,
    experience: '8 Tahun Head Coach Barcelona & Jakarta',
    image: 'assets/images/coach_edu_altimires.jpg',
    specialties: ['Bandeja & Vibora Master', 'Taktik Turnamen Double', 'Footwork Cepat'],
    availableVenues: ['Padel Pro Kemang', 'Social Padel House Menteng', 'Verde Sports Hub PIK 2'],
    bio: 'Pelatih kepala asal Spanyol bersertifikat FIP Level 2. Berpengalaman membina atlet turnamen internasional dan program masterclass taktik padel ganda.',
  ),
  Coach(
    id: 'coach2',
    name: 'Adrià Mercadal',
    title: 'FIP Pro Master & Senior Coach',
    rating: 4.95,
    reviewsCount: 142,
    ratePerHour: 280,
    experience: 'Mantan Pemain World Padel Tour',
    image: 'assets/images/coach_adria_mercadal.png',
    specialties: ['Power Smash Por Tres', 'Wall Rebound Defense', 'Match Intelligence'],
    availableVenues: ['Social Padel House Setiabudi', 'Rekket Space Padel Hall', 'SPACE PADEL PIK 2'],
    bio: 'Pemain sirkuit profesional Spanyol dengan teknik wall rebound kelas dunia. Spesialis dalam transisi bertahan ke counter-attack eksplosif.',
  ),
  Coach(
    id: 'coach3',
    name: 'Adi Sila Pratama',
    title: 'Senior Sparring Partner & National Coach',
    rating: 4.90,
    reviewsCount: 126,
    ratePerHour: 220,
    experience: 'Mantan Atlet Tenis & Padel Nasional',
    image: 'assets/images/coach_adi_sila.jpg',
    specialties: ['Transisi Tenis ke Padel', 'Drill Ketahanan Rally', 'Volley Control'],
    availableVenues: ['Padel Pro Kemang', 'Maison de Padel', 'Artepola Padel Kemang'],
    bio: 'Spesialis mengarahkan pemain tenis beralih ke padel secara natural tanpa cedera siku, menguasai kontrol sudut spin kaca yang akurat.',
  ),
  Coach(
    id: 'coach4',
    name: 'Imron Jasuli',
    title: 'Bali Academy Coach & Clinic Lead',
    rating: 4.92,
    reviewsCount: 95,
    ratePerHour: 200,
    experience: '6 Tahun Melatih di Canggu & Sanur',
    image: 'assets/images/coach_imron_jasuli.jpg',
    specialties: ['Fundamental Grip & Stance', 'Konsistensi Rally Panjang', 'Fun Coaching'],
    availableVenues: ['HPC Atlas Beach Club', 'Bali Social Club Canggu', 'Jungle Padel Canggu'],
    bio: 'Pelatih ramah, komunikatif, dan sabar yang fokus membangun fondasi teknik yang benar serta keseruan bermain bagi pemula hingga intermediate.',
  ),
];


