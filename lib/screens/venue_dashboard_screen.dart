import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../data.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';

class VenueDashboardScreen extends StatefulWidget {
  const VenueDashboardScreen({super.key});

  @override
  State<VenueDashboardScreen> createState() => _VenueDashboardScreenState();
}

class _VenueDashboardScreenState extends State<VenueDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();

  late Court _selectedCourt;
  DateTime _selectedDate = DateTime.now();

  // Ticket verification state
  bool _isVerifying = false;
  Booking? _verifiedBooking;
  String? _verificationMessage;
  bool _verificationSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = UserStore.instance.profile;
    _selectedCourt = courts.firstWhere(
      (c) => c.id == user.managedCourtId,
      orElse: () => courts.first,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _verifyTicket(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode booking terlebih dahulu.')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _verifiedBooking = null;
      _verificationMessage = null;
    });

    // 1. Try local store
    final localBooking = BookingStore.instance.findBookingById(clean);

    // 2. Try backend API asynchronously
    final apiResult = await ApiService.instance.verifyTicket(clean);

    setState(() {
      _isVerifying = false;
      if (localBooking != null) {
        _verifiedBooking = localBooking;
        _verificationSuccess = true;
        _verificationMessage = localBooking.isCheckedIn
            ? 'Tiket ini SUDAH PERNAH Check-in sebelumnya.'
            : (localBooking.status == 'Dibatalkan'
                ? 'Tiket ini telah DIBATALKAN.'
                : 'Tiket VALID dan terverifikasi!');
      } else if (apiResult != null && apiResult['success'] == true) {
        final bData = apiResult['data'] as Map<String, dynamic>;
        final courtId = bData['courtId'] as String;
        final c = courts.firstWhere((x) => x.id == courtId, orElse: () => courts.first);
        _verifiedBooking = Booking(
          id: bData['id'] as String?,
          court: c,
          date: DateTime.tryParse(bData['date'] ?? '') ?? DateTime.now(),
          slot: bData['slot'] ?? '18:00',
          paymentMethod: bData['paymentMethod'] ?? 'Bayar di tempat',
          status: bData['status'] ?? 'Terkonfirmasi',
        );
        _verificationSuccess = true;
        _verificationMessage = apiResult['message'] ?? 'Tiket valid!';
      } else {
        _verificationSuccess = false;
        _verificationMessage = apiResult?['message'] ??
            'Kode booking tidak ditemukan dalam sistem reservasi.';
      }
    });
  }

  void _confirmCheckIn(Booking booking) {
    final success = BookingStore.instance.checkIn(booking.id);
    if (success) {
      setState(() {
        _verifiedBooking = booking.copyWith(status: 'Check-in Selesai');
        _verificationMessage = 'Pemain berhasil CHECK-IN! Selamat bermain.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Row(
            children: [
              const Icon(LucideIcons.circleCheck, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Check-in selesai untuk booking #${booking.id}!'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showMaintenanceDialog(String slot) {
    String selectedReason = 'Perawatan Rutin Lapangan';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AP.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Tutup Slot $slot?',
            style: const TextStyle(fontFamily: 'Display', fontWeight: FontWeight.w800, fontSize: 20.7),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slot $slot pada ${_formatDateShort(_selectedDate)} akan ditutup untuk reservasi umum.',
                style:  TextStyle(color: AP.slate, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alasan Penutupan:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AP.cloud,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Perawatan Rutin Lapangan',
                    child: Text('Perawatan Rutin Lapangan'),
                  ),
                  DropdownMenuItem(
                    value: 'Pembersihan Kaca & Net',
                    child: Text('Pembersihan Kaca & Net'),
                  ),
                  DropdownMenuItem(
                    value: 'Event / Turnamen Internal',
                    child: Text('Event / Turnamen Internal'),
                  ),
                  DropdownMenuItem(
                    value: 'Perbaikan Karpet Rumput',
                    child: Text('Perbaikan Karpet Rumput'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDlgState(() => selectedReason = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:  Text('Batal', style: TextStyle(color: AP.slate)),
            ),
            ElevatedButton(
              onPressed: () {
                BookingStore.instance.toggleMaintenance(
                  _selectedCourt,
                  _selectedDate,
                  slot,
                  block: true,
                  reason: selectedReason,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Slot $slot berhasil ditutup untuk $selectedReason.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tutup Slot',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _unblockSlot(String slot) {
    BookingStore.instance.toggleMaintenance(
      _selectedCourt,
      _selectedDate,
      slot,
      block: false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Slot $slot dibuka kembali untuk umum.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.blueDark,
        elevation: 0,
        toolbarHeight: 68,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Portal Pengelola',
              style: TextStyle(fontFamily: 'Display', height: 1.1,
                color: Colors.white,
                fontSize: 19.55,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _selectedCourt.venue,
              style: const TextStyle(
                color: AP.lime,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                UserStore.instance.switchRole('player');
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.arrowLeftRight, color: AP.lime, size: 16),
              label: const Text(
                'Mode Pemain',
                style: TextStyle(
                  color: AP.lime,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AP.blueDark,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AP.lime,
              indicatorWeight: 3,
              labelColor: AP.lime,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(LucideIcons.scan, size: 18), text: 'Validasi QR'),
                Tab(icon: Icon(LucideIcons.calendarDays, size: 18), text: 'Jadwal Slot'),
                Tab(icon: Icon(LucideIcons.chartBar, size: 18), text: 'Laporan'),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: BookingStore.instance,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildValidationTab(),
              _buildScheduleTab(),
              _buildReportTab(),
            ],
          );
        },
      ),
    );
  }

  // ================= TAB 1: VALIDASI TIKET QR ================= //
  Widget _buildValidationTab() {
    return APList(
      padding: const EdgeInsets.all(16),
      children: [
        // Venue Selector Banner
        _buildVenueSelectorBanner(),
        const SizedBox(height: 16),

        // Quick Stats Strip
        _buildStatsRow(),
        const SizedBox(height: 16),

        // Scanner viewfinder card
        Container(
          padding: const EdgeInsets.all(20),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AP.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:  Icon(LucideIcons.scan, color: AP.blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                   Text(
                    'Pemindai Tiket Masuk',
                    style: TextStyle(fontFamily: 'Display', 
                      fontSize: 18.4,
                      fontWeight: FontWeight.w800,
                      color: AP.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Simulated QR Viewfinder Box
              Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AP.blueDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner markers
                    Positioned(
                      top: 24,
                      left: 24,
                      child: _scannerCorner(isTop: true, isLeft: true),
                    ),
                    Positioned(
                      top: 24,
                      right: 24,
                      child: _scannerCorner(isTop: true, isLeft: false),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      child: _scannerCorner(isTop: false, isLeft: true),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: _scannerCorner(isTop: false, isLeft: false),
                    ),

                    // Center scan graphic
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.scan,
                          size: 48,
                          color: AP.lime,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Arahkan kamera ke QR Code E-Ticket Pemain',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Manual Input Field
               Text(
                'Atau Ketik Kode Booking Manual:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AP.ink,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Contoh: ACE-C1-1800',
                        hintStyle:  TextStyle(fontSize: 13, color: AP.slate),
                        filled: true,
                        fillColor: AP.cloud,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () => _codeController.clear(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isVerifying
                        ? null
                        : () => _verifyTicket(_codeController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AP.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Cek Tiket',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ),

              // Quick Test Preset Buttons
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                   Text(
                    'Coba cepat:',
                    style: TextStyle(color: AP.slate, fontSize: 12),
                  ),
                  ...BookingStore.instance.bookings.take(2).map((b) => GestureDetector(
                        onTap: () {
                          _codeController.text = b.id;
                          _verifyTicket(b.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AP.lime.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AP.lime.withValues(alpha: 0.8)),
                          ),
                          child: Text(
                            b.id,
                            style:  TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AP.ink,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Verification Result Section
        if (_verificationMessage != null) _buildVerificationCard(),

        const SizedBox(height: 20),

        // Recent Checked-in Log
        _buildCheckedInLog(),
      ],
    );
  }

  Widget _scannerCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AP.lime, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AP.lime, width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AP.lime, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AP.lime, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildVerificationCard() {
    final b = _verifiedBooking;
    final isCheckedIn = b?.isCheckedIn ?? false;
    final isCancelled = b?.status == 'Dibatalkan';

    final Color statusColor = isCheckedIn
        ? AP.blue
        : (isCancelled || !_verificationSuccess
            ? Colors.red
            : const Color(0xFF16A34A));

    final IconData statusIcon = isCheckedIn
        ? LucideIcons.badgeCheck
        : (isCancelled || !_verificationSuccess
            ? LucideIcons.circleX
            : LucideIcons.circleCheck);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _verificationMessage ?? '',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (b != null) ...[
             Divider(height: 24, color: AP.line),
            _infoRow('Kode Tiket', b.id),
            _infoRow('Lapangan', '${b.court.name} (${b.court.venue})'),
            _infoRow('Jadwal Main', '${_formatDateShort(b.date)} | ${b.slot} WIB'),
            _infoRow('Metode Bayar', b.paymentMethod),
            _infoRow('Total Biaya', 'Rp${b.finalPrice}.000'),
            _infoRow('Status Saat Ini', b.status),

            if (!isCheckedIn && !isCancelled) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmCheckIn(b),
                  icon: const Icon(LucideIcons.userCheck, size: 20),
                  label: const Text(
                    'Konfirmasi Check-In Pemain',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style:  TextStyle(color: AP.slate, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style:  TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AP.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedInLog() {
    final checkedInBookings = BookingStore.instance.bookings
        .where((b) => b.court.id == _selectedCourt.id && b.isCheckedIn)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(
                child: Text(
                  'Daftar Check-in Hari Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AP.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AP.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${checkedInBookings.length} Pemain',
                  style:  TextStyle(
                    color: AP.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (checkedInBookings.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child:  Column(
                children: [
                  Icon(LucideIcons.clipboardCheck,
                      size: 36, color: AP.slate),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada pemain yang check-in hari ini.',
                    style: TextStyle(color: AP.slate, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checkedInBookings.length,
              separatorBuilder: (_, __) =>  Divider(color: AP.line, height: 16),
              itemBuilder: (context, i) {
                final b = checkedInBookings[i];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      child: const Icon(LucideIcons.check,
                          color: Color(0xFF16A34A), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.id,
                            style:  TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AP.ink,
                            ),
                          ),
                          Text(
                            'Slot ${b.slot} WIB • ${b.paymentMethod}',
                            style:
                                 TextStyle(color: AP.slate, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SELESAI',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ================= TAB 2: MANAJEMEN JADWAL & SLOT ================= //
  Widget _buildScheduleTab() {
    final dailyBookings = BookingStore.instance.getBookingsForCourtAndDate(
      _selectedCourt.id,
      _selectedDate,
    );

    return APList(
      padding: const EdgeInsets.all(16),
      children: [
        // Venue Selector Banner
        _buildVenueSelectorBanner(),
        const SizedBox(height: 16),

        // Date Picker Horizontal Strip
        _buildDateStrip(),
        const SizedBox(height: 16),

        // Slot Status Explainer
        Row(
          children: [
            _legendItem(const Color(0xFF16A34A), 'Tersedia'),
            const SizedBox(width: 12),
            _legendItem(AP.blue, 'Terisi'),
            const SizedBox(width: 12),
            _legendItem(Colors.orange.shade800, 'Maintenance'),
          ],
        ),
        const SizedBox(height: 14),

        // 14 Time Slots (08:00 - 22:00)
        ...allSlots.map((slot) {
          final booking =
              dailyBookings.where((b) => b.slot == slot).firstOrNull;
          return _buildSlotCard(slot, booking);
        }),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style:  TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AP.slate,
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard(String slot, Booking? booking) {
    final bool isAvailable = booking == null;
    final bool isMaintenance = booking?.isMaintenance ?? false;
    final bool isBooked = booking != null && !isMaintenance;

    Color badgeColor = const Color(0xFF16A34A);
    String statusTitle = 'Tersedia untuk Reservasi';
    if (isMaintenance) {
      badgeColor = Colors.orange.shade800;
      statusTitle = 'Ditutup (Perawatan Lapangan)';
    } else if (isBooked) {
      badgeColor = AP.blue;
      statusTitle = booking.isCheckedIn
          ? 'Terisi • Pemain Check-in'
          : 'Terisi (${booking.status})';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMaintenance
              ? Colors.orange.shade200
              : (isBooked ? AP.blue.withValues(alpha: 0.25) : AP.line),
        ),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AP.cloud,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              slot,
              style:  TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AP.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusTitle,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isBooked
                      ? 'ID: ${booking.id} • ${booking.paymentMethod}'
                      : (isMaintenance
                          ? 'Mitra Lapangan'
                          : 'Tarif normal: Rp${_selectedCourt.pricePerHour}.000'),
                  style:  TextStyle(color: AP.slate, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action Buttons
          if (isAvailable)
            TextButton.icon(
              onPressed: () => _showMaintenanceDialog(slot),
              icon: const Icon(LucideIcons.wrench, size: 14),
              label: const Text('Tutup Slot', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                backgroundColor: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          else if (isMaintenance)
            ElevatedButton(
              onPressed: () => _unblockSlot(slot),
              style: ElevatedButton.styleFrom(
                backgroundColor: AP.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Buka Slot',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            )
          else if (isBooked && !booking.isCheckedIn)
            ElevatedButton(
              onPressed: () {
                _codeController.text = booking.id;
                _tabController.animateTo(0);
                _verifyTicket(booking.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Check-in',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    final now = DateTime.now();
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = now.add(Duration(days: i));
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AP.blueDark : AP.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AP.blueDark : AP.line,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    i == 0
                        ? 'Hari Ini'
                        : (i == 1 ? 'Besok' : _dayName(date.weekday)),
                    style: TextStyle(
                      color: isSelected ? AP.lime : AP.slate,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day} ${_monthName(date.month)}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AP.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= TAB 3: LAPORAN & KEUANGAN ================= //
  Widget _buildReportTab() {
    final stats = BookingStore.instance.getVenueStats(_selectedCourt.id);
    final totalBookings = stats['totalBookings'] as int? ?? 0;
    final checkedIn = stats['checkedInCount'] as int? ?? 0;
    final revenue = stats['estimatedRevenue'] as int? ?? 0;
    final pay = (stats['paymentCounts'] as Map?)?.cast<String, int>() ?? const <String, int>{};
    final payTotal = pay.values.fold<int>(0, (a, b) => a + b);
    final payRows = pay.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return APList(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVenueSelectorBanner(),
        const SizedBox(height: 16),

        // Revenue Hero Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient:  LinearGradient(
              colors: [AP.blueDark, AP.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimasi Pendapatan Venue',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Icon(LucideIcons.coins, color: AP.lime),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rp$revenue.000',
                style: const TextStyle(fontFamily: 'Display', 
                  color: AP.lime,
                  fontSize: 31.36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Berdasarkan total sesi booking aktif dan selesai di lapangan ini.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Breakdown Cards
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Total Reservasi',
                '$totalBookings Sesi',
                LucideIcons.calendar,
                AP.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Check-in Selesai',
                '$checkedIn Pemain',
                LucideIcons.userCheck,
                const Color(0xFF16A34A),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Payment Methods Breakdown
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AP.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AP.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Metode Pembayaran Pemain',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AP.ink,
                ),
              ),
              const SizedBox(height: 14),
              if (payTotal == 0)
                 Text('Belum ada transaksi untuk venue ini.',
                    style: TextStyle(color: AP.slate, fontSize: 13))
              else
                for (var i = 0; i < payRows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _paymentBar(
                    payRows[i].key,
                    payRows[i].value / payTotal,
                    '${(payRows[i].value * 100 / payTotal).round()}%${i == 0 ? ' (Terpopuler)' : ''}',
                  ),
                ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Hotline Partner Support
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AP.lime.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AP.lime),
          ),
          child: Row(
            children: [
               Icon(LucideIcons.headset, color: AP.onLime, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Bantuan Mitra Lapangan Ace Padel',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AP.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Butuh bantuan operasional atau penarikan dana? Hubungi PIC Mitra kami.',
                      style: TextStyle(
                        color: AP.ink.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontFamily: 'Display', 
              fontSize: 20.7,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:  TextStyle(color: AP.slate, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _paymentBar(String title, double fraction, String percentLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:  TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AP.ink)),
            Text(percentLabel,
                style:  TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AP.slate)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AP.cloud,
            valueColor:  AlwaysStoppedAnimation(AP.blue),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ================= SHARED COMPONENTS ================= //
  Widget _buildVenueSelectorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AP.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AP.lime.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child:  Icon(LucideIcons.store, color: AP.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Court>(
                value: _selectedCourt,
                isExpanded: true,
                items: courts.map((c) {
                  return DropdownMenuItem<Court>(
                    value: c,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          c.name,
                          style:  TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AP.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          c.venue,
                          style:  TextStyle(color: AP.slate, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newCourt) {
                  if (newCourt != null) {
                    setState(() => _selectedCourt = newCourt);
                    UserStore.instance.setManagedCourt(newCourt.id);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = BookingStore.instance.getVenueStats(_selectedCourt.id);
    final total = stats['totalBookings'] as int? ?? 0;
    final checkedIn = stats['checkedInCount'] as int? ?? 0;
    final revenue = stats['estimatedRevenue'] as int? ?? 0;

    return Row(
      children: [
        _miniStat('Sesi', '$total', AP.blue),
        const SizedBox(width: 8),
        _miniStat('Check-in', '$checkedIn', const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        _miniStat('Pendapatan', 'Rp$revenue.000', AP.blueDark),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AP.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AP.line),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:  TextStyle(color: AP.slate, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateShort(DateTime d) {
    return '${d.day} ${_monthName(d.month)} ${d.year}';
  }

  String _dayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Sen';
      case 2:
        return 'Sel';
      case 3:
        return 'Rab';
      case 4:
        return 'Kam';
      case 5:
        return 'Jum';
      case 6:
        return 'Sab';
      default:
        return 'Min';
    }
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[m - 1];
  }
}
