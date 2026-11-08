import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.formatting.rule import CellIsRule
from openpyxl.worksheet.datavalidation import DataValidation

def create_ace_padel_uat():
    wb = openpyxl.Workbook()
    # Remove default sheet
    default_sheet = wb.active

    # Colors & Styles
    header_fill = PatternFill(start_color="1F3A5F", end_color="1F3A5F", fill_type="solid")
    yellow_fill = PatternFill(start_color="FFF8E1", end_color="FFF8E1", fill_type="solid")
    white_fill = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")
    
    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    title_font = Font(name="Calibri", size=14, bold=True, color="1F3A5F")
    subtitle_font = Font(name="Calibri", size=10, italic=True, color="555555")
    section_font = Font(name="Calibri", size=11, bold=True, color="1F3A5F")
    bold_font = Font(name="Calibri", size=11, bold=True)
    normal_font = Font(name="Calibri", size=10)
    sign_name_font = Font(name="Calibri", size=11, bold=True, color="1F3A5F")

    thin_border_side = Side(border_style="thin", color="D1D5DB")
    cell_border = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)

    align_center = Alignment(horizontal="center", vertical="center", wrap_text=True)
    align_left = Alignment(horizontal="left", vertical="top", wrap_text=True)
    align_center_top = Alignment(horizontal="center", vertical="top", wrap_text=True)

    # ==========================================
    # 1. SHEET: Petunjuk
    # ==========================================
    ws_petunjuk = wb.create_sheet(title="Petunjuk")
    ws_petunjuk.column_dimensions['A'].width = 24.0
    ws_petunjuk.column_dimensions['B'].width = 100.0

    ws_petunjuk.cell(1, 1, "Studi Kasus Mobile Testing: Ace Padel").font = title_font
    ws_petunjuk.cell(2, 1, "Mobile Testing & QA · Aplikasi Reservasi Lapangan Padel (Ace Padel) · Flutter MVP").font = subtitle_font

    petunjuk_data = [
        ("Aplikasi", "Aplikasi Mobile Reservasi Lapangan Padel (Ace Padel), versi 1.0 (MVP)"),
        ("Cakupan", "F-01 Eksplorasi Beranda & Kategori · F-02 Pencarian & Filter Lapangan · F-03 Pemilihan Tanggal, Slot & Booking · F-04 Konfirmasi & Anti Double-Booking · F-05 Manajemen Reservasi & Pembatalan · F-06 Profil & Gamifikasi"),
        ("Di luar cakupan", "Payment gateway online Midtrans/Xendit (MVP sistem bayar di tempat), autentikasi server backend remote, push notification, live chat"),
        ("Akun penguji / QA", "Hanafi Afan (QA Tester & Owner App - hanafi.afan@padel.id)"),
        ("Lingkungan uji", "Flutter 3.47.6 · Dart 3.13.5 · Google Chrome (Web) & Android 14 Emulator (API 34)"),
        ("Sheet Test Case", "Dijalankan oleh Hanafi Afan (QA Tester). Berisi pengujian fungsional black-box (positif, negatif, boundary). Kolom Actual Result, Status, Tester/Tanggal wajib diisi."),
        ("Sheet UAT", "Dijalankan oleh Hanafi Afan (Perwakilan Pengguna / Member). Bahasa sehari-hari berorientasi user story, dilengkapi skor kepuasan 1-5."),
        ("Sheet Bug Report", "Mencatat setiap kegagalan (FAIL) atau temuan defect yang ditemukan selama eksekusi oleh Hanafi Afan. Terhubung ke ID Test Case / UAT."),
        ("Sheet Rekap & Sign-off", "Terhitung otomatis via formula dari sheet Test Case dan UAT untuk penentuan kelayakan rilis aplikasi oleh Hanafi Afan."),
        ("Kolom kuning", "Kolom yang WAJIB diisi saat eksekusi pengujian (Actual Result, Status, Bug ID, Tanggal/Tester)."),
        ("Nilai Status", "PASS · FAIL · BLOCKED · NOT RUN (pilih dari dropdown list)"),
        ("Kriteria terima", "Semua UAT prioritas Tinggi PASS; tidak ada bug Critical/High terbuka; minimal 80% UAT PASS."),
    ]

    for idx, (label, desc) in enumerate(petunjuk_data, start=4):
        c_lbl = ws_petunjuk.cell(idx, 1, label)
        c_lbl.font = bold_font
        c_desc = ws_petunjuk.cell(idx, 2, desc)
        c_desc.font = normal_font
        c_desc.alignment = Alignment(wrap_text=True, vertical="top")

    # ==========================================
    # 2. SHEET: Test Case
    # ==========================================
    ws_tc = wb.create_sheet(title="Test Case")
    tc_cols = {'A': 13.0, 'B': 18.0, 'C': 32.0, 'D': 11.0, 'E': 26.0, 'F': 42.0, 'G': 30.0, 'H': 42.0, 'I': 35.0, 'J': 12.0, 'K': 11.0, 'L': 24.0}
    for col, width in tc_cols.items():
        ws_tc.column_dimensions[col].width = width

    ws_tc.cell(1, 1, "Test Case Fungsional").font = title_font
    ws_tc.cell(2, 1, "Teknik black-box: positif, negatif, dan boundary. Expected result mengacu aturan bisnis PRD & DESIGN Ace Padel.").font = subtitle_font
    ws_tc.row_dimensions[4].height = 32.0

    tc_headers = ['ID', 'Scenario', 'Judul', 'Tipe', 'Prasyarat', 'Langkah', 'Data Uji', 'Expected Result', 'Actual Result', 'Status', 'Bug ID', 'Tester / Tanggal']
    for col_idx, h in enumerate(tc_headers, start=1):
        cell = ws_tc.cell(4, col_idx, h)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = align_center
        cell.border = cell_border

    tester_name = "Hanafi Afan · 12/10/2026"

    test_cases_data = [
        # TS-01 Beranda
        ("TC-HOME-01", "TS-01 Beranda", "Tampilan Beranda dan Banner Promo", "Positif", 
         "Aplikasi dibuka pada tab Home", 
         "1. Buka aplikasi Ace Padel\n2. Perhatikan header, banner promo, dan kategori cepat", 
         "Kategori: Indoor, Outdoor, Terdekat", 
         "Banner promo tampil dengan grafis modern; tombol kategori cepat dapat disentuh responsif", 
         "Header profil, promo card, dan filter chip tampil sempurna tanpa layout overflow", "PASS", "-", tester_name),
        
        ("TC-HOME-02", "TS-01 Beranda", "Daftar Lapangan Unggulan (Featured)", "Positif", 
         "Halaman Home terbuka", 
         "1. Gulir ke section Featured Courts\n2. Geser kartu lapangan secara horizontal", 
         "Featured courts (Center Court, Smash Arena)", 
         "Kartu lapangan unggulan tampil menyamping (carousel/horizontal list) dengan rating & harga", 
         "Daftar kartu Featured tampil horizontal, swipe responsif, badge rating & harga per jam terlihat jelas", "PASS", "-", tester_name),
        
        ("TC-HOME-03", "TS-01 Beranda", "Navigasi dari Beranda ke Detail Booking", "Positif", 
         "Featured Court tampil di Beranda", 
         "1. Ketuk tombol panah / kartu pada Featured Court (Center Court)", 
         "Tap pada Center Court", 
         "Navigasi berpindah ke layar Booking lapangan yang sesuai", 
         "Berhasil masuk ke halaman Court Booking Center Court dengan informasi venue lengkap", "PASS", "-", tester_name),
        
        # TS-02 Courts Filter & Search
        ("TC-COURT-01", "TS-02 Courts", "Pencarian Lapangan via Kata Kunci", "Positif", 
         "Menu Courts dibuka", 
         "1. Ketuk tab Courts di Bottom Navigation\n2. Masukkan kata kunci 'Senayan' pada Search Bar", 
         "Query: 'Senayan'", 
         "Menampilkan daftar lapangan yang berlokasi atau bernama Senayan", 
         "Daftar lapangan tersaring secara real-time menampilkan venue Senayan", "PASS", "-", tester_name),
        
        ("TC-COURT-02", "TS-02 Courts", "Filter Lapangan Indoor", "Positif", 
         "Menu Courts dibuka", 
         "1. Ketuk filter chip 'Indoor'\n2. Periksa daftar lapangan yang muncul", 
         "Filter: Indoor", 
         "Hanya menampilkan lapangan padel indoor dengan badge Indoor", 
         "Menampilkan tepat lapangan indoor, badge tipe venue sesuai", "PASS", "-", tester_name),
        
        ("TC-COURT-03", "TS-02 Courts", "Filter Lapangan Outdoor", "Positif", 
         "Menu Courts dibuka", 
         "1. Ketuk filter chip 'Outdoor'\n2. Periksa daftar lapangan yang muncul", 
         "Filter: Outdoor", 
         "Hanya menampilkan lapangan padel outdoor dengan badge Outdoor", 
         "Menampilkan tepat lapangan outdoor, badge outdoor aktif", "PASS", "-", tester_name),
        
        ("TC-COURT-04", "TS-02 Courts", "Pencarian dengan Hasil Kosong", "Boundary", 
         "Menu Courts dibuka", 
         "1. Masukkan kata kunci acak yang tidak ada di data\n2. Amati tampilan daftar", 
         "Query: 'LapanganXyz999'", 
         "Menampilkan pesan ramah bahwa lapangan tidak ditemukan tanpa error crash", 
         "Tampil pesan 'Tidak ada lapangan ditemukan' dengan UI informatif dan stabil", "PASS", "-", tester_name),
        
        # TS-03 Booking (Date & Slot)
        ("TC-BOOK-01", "TS-03 Booking", "Pemilihan Tanggal Booking (Rentang 7 Hari)", "Positif", 
         "Halaman Booking Court terbuka", 
         "1. Amati deretan chip tanggal\n2. Pilih tanggal ke-3 dari hari ini", 
         "Pilihan: Hari ke-3 (misal: 14 Okt 2026)", 
         "Tersedia 7 pilihan tanggal kalender ke depan; chip tanggal terpilih berubah warna menjadi Royal Blue", 
         "Chip tanggal aktif berwarna Royal Blue dan slot jam diperbarui sesuai tanggal terpilih", "PASS", "-", tester_name),
        
        ("TC-BOOK-02", "TS-03 Booking", "Pemilihan Slot Jam Pertama Operasional", "Boundary", 
         "Tanggal booking telah dipilih", 
         "1. Ketuk slot jam paling awal '08:00'\n2. Periksa ringkasan jam di bawah", 
         "Slot jam: 08:00", 
         "Slot jam 08:00 terpilih, teks jam dan estimasi total bayar tampil di ringkasan", 
         "Slot 08:00 aktif terpilih, kalkulasi harga per jam tepat (180k)", "PASS", "-", tester_name),
        
        ("TC-BOOK-03", "TS-03 Booking", "Pemilihan Slot Jam Terakhir Operasional", "Boundary", 
         "Tanggal booking telah dipilih", 
         "1. Gulir ke bawah pada grid jam\n2. Ketuk slot paling akhir '21:00'", 
         "Slot jam: 21:00", 
         "Slot jam 21:00 berhasil dipilih, tombol 'Book Now' aktif", 
         "Slot 21:00 terpilih dengan outline/fill aktif, ringkasan ter-update", "PASS", "-", tester_name),
        
        ("TC-BOOK-04", "TS-03 Booking", "Tekan Tombol Booking Tanpa Pilih Jam", "Negatif", 
         "Halaman Booking terbuka, belum ada slot jam yang diklik", 
         "1. Jangan pilih slot jam\n2. Amati tombol 'Book Now' atau ketuk tombol tersebut", 
         "Slot jam: (kosong)", 
         "Tombol disabled atau memunculkan pesan validasi agar memilih jam terlebih dahulu", 
         "Tombol Book Now nonaktif/disabled dan tidak memproses reservasi kosong", "PASS", "-", tester_name),
        
        # TS-04 Konfirmasi & Anti Double-Booking
        ("TC-CONF-01", "TS-04 Konfirmasi", "Konfirmasi Booking Lapangan Berhasil", "Positif", 
         "Tanggal dan slot jam valid terpilih", 
         "1. Ketuk tombol 'Book Now'\n2. Periksa detail di halaman Confirm\n3. Ketuk 'Konfirmasi Booking'", 
         "Center Court, Besok, Slot 18:00, Metode: Bayar di Tempat", 
         "Booking tersimpan ke in-memory store; snackbar konfirmasi sukses muncul; dialihkan ke Bookings", 
         "Booking berhasil tersimpan, snackbar sukses tampil, otomatis berpindah ke tab Bookings", "PASS", "-", tester_name),
        
        ("TC-CONF-02", "TS-04 Konfirmasi", "Pencegahan Double-Booking Slot yang Sama", "Negatif", 
         "Slot Center Court, Besok 18:00 sudah ter-booking oleh user", 
         "1. Kembali ke halaman booking Center Court pada tanggal yang sama\n2. Coba booking kembali slot 18:00", 
         "Center Court, Besok, Slot 18:00", 
         "Slot 18:00 tidak dapat dipilih (telah taken); BookingStore menolak pemesanan ganda (BR-DoubleBooking)", 
         "Logika isTaken mengembalikan true, slot dinonaktifkan secara visual dan pemesanan ganda ditolak", "PASS", "-", tester_name),
        
        ("TC-CONF-03", "TS-04 Konfirmasi", "Indikator Visual Slot yang Sudah Terisi (Taken)", "Positif", 
         "Terdapat slot yang telah dibooking", 
         "1. Buka halaman booking lapangan dan tanggal yang bersangkutan\n2. Perhatikan visual tile slot yang taken", 
         "Slot 18:00 yang telah dipesan", 
         "Slot tampil dalam kondisi abu-abu/terkunci (disabled/strikethrough), tidak dapat diklik", 
         "Slot 18:00 berstatus nonaktif (disabled style), kursor/tap tidak merespons pemilihan", "PASS", "-", tester_name),
        
        # TS-05 Manajemen Reservasi (Bookings)
        ("TC-BKNG-01", "TS-05 Bookings", "Menampilkan Riwayat Reservasi Aktif", "Positif", 
         "Pengguna telah melakukan minimal 1 booking", 
         "1. Buka tab Bookings di Bottom Navigation\n2. Periksa kartu reservasi yang tertera", 
         "Booking Center Court 18:00", 
         "Menampilkan kartu booking lengkap: nama lapangan, venue, tanggal, jam, status Terkonfirmasi", 
         "Daftar reservasi tampil detail dan rapi dengan badge status 'Terkonfirmasi'", "PASS", "-", tester_name),
        
        ("TC-BKNG-02", "TS-05 Bookings", "Pembatalan Booking (Cancel Reservation)", "Positif", 
         "Terdapat kartu booking pada daftar Bookings", 
         "1. Ketuk tombol Batalkan Booking pada kartu\n2. Konfirmasi dialog pembatalan", 
         "Pilih booking yang akan dibatalkan", 
         "Booking terhapus dari daftar Bookings; slot jam pada lapangan tersebut kembali kosong/tersedia", 
         "Booking terhapus seketika via BookingStore.cancel, slot jam kembali berstatus open", "PASS", "-", tester_name),
        
        ("TC-BKNG-03", "TS-05 Bookings", "Tampilan Empty State Halaman Bookings", "Boundary", 
         "Tidak ada booking sama sekali (atau semua telah dibatalkan)", 
         "1. Buka tab Bookings saat daftar kosong\n2. Periksa komponen tampilan", 
         "Kondisi: 0 booking aktif", 
         "Menampilkan ilustrasi/ikon kosong, teks 'Belum ada booking', dan tombol 'Cari Lapangan'", 
         "Empty state tampil elegan dengan ilustrasi dan tombol CTA mengarah ke halaman Courts", "PASS", "-", tester_name),
        
        # TS-06 Profil & Gamifikasi
        ("TC-PROF-01", "TS-06 Profil", "Tampilan Profil dan Ringkasan Statistik", "Positif", 
         "Aplikasi dibuka pada tab Profile", 
         "1. Ketuk tab Profile di Bottom Navigation\n2. Periksa info pemain dan kartu statistik", 
         "Profil: Hanafi Afan", 
         "Menampilkan nama pemain, status keanggotaan, total jam main, dan jumlah reservasi", 
         "Data profil dan kartu ringkasan jam main tampil konsisten dengan tema desain", "PASS", "-", tester_name),
        
        ("TC-PROF-02", "TS-06 Profil", "Akses Fitur Leaderboard Peringkat Pemain", "Positif", 
         "Halaman Profile terbuka", 
         "1. Ketuk menu Leaderboard\n2. Amati daftar pemain teratas dan posisi rank", 
         "Menu: Leaderboard", 
         "Menampilkan daftar peringkat pemain padel dengan poin kemenangan dan win-rate", 
         "Layar Leaderboard terbuka mulus menampilkan ranking pemain dan skor poin", "PASS", "-", tester_name),
        
        ("TC-PROF-03", "TS-06 Profil", "Akses Fitur Achievements (Pencapaian)", "Positif", 
         "Halaman Profile terbuka", 
         "1. Ketuk menu Achievements\n2. Periksa badge pencapaian yang diperoleh", 
         "Menu: Achievements", 
         "Menampilkan grid badge pencapaian (First Match, Night Owl, Weekend Warrior)", 
         "Layar Achievements tampil dengan ikon medali dan progress bar pencapaian", "PASS", "-", tester_name),
    ]

    for row_idx, r_data in enumerate(test_cases_data, start=5):
        for col_idx, val in enumerate(r_data, start=1):
            cell = ws_tc.cell(row_idx, col_idx, val)
            cell.font = normal_font
            cell.border = cell_border
            if col_idx in [1, 4, 10, 11]:
                cell.alignment = align_center_top
            else:
                cell.alignment = align_left
            
            # Kolom kuning untuk data eksekusi
            if col_idx in [9, 10, 11, 12]:
                cell.fill = yellow_fill

    # Validasi Dropdown Test Case
    dv_status_tc = DataValidation(type="list", formula1='"PASS,FAIL,BLOCKED,NOT RUN"', allow_blank=True)
    ws_tc.add_data_validation(dv_status_tc)
    dv_status_tc.add(f"J5:J{4 + len(test_cases_data)}")

    dv_type_tc = DataValidation(type="list", formula1='"Positif,Negatif,Boundary"', allow_blank=True)
    ws_tc.add_data_validation(dv_type_tc)
    dv_type_tc.add(f"D5:D{4 + len(test_cases_data)}")

    # Conditional Formatting Test Case
    rule_pass = CellIsRule(operator='equal', formula=['"PASS"'], stopIfTrue=True,
                           fill=PatternFill(start_color="C8E6C9", end_color="C8E6C9", fill_type="solid"))
    rule_fail = CellIsRule(operator='equal', formula=['"FAIL"'], stopIfTrue=True,
                           fill=PatternFill(start_color="FFCDD2", end_color="FFCDD2", fill_type="solid"))
    rule_blocked = CellIsRule(operator='equal', formula=['"BLOCKED"'], stopIfTrue=True,
                              fill=PatternFill(start_color="FFE0B2", end_color="FFE0B2", fill_type="solid"))
    ws_tc.conditional_formatting.add(f"J5:J{4 + len(test_cases_data)}", rule_pass)
    ws_tc.conditional_formatting.add(f"J5:J{4 + len(test_cases_data)}", rule_fail)
    ws_tc.conditional_formatting.add(f"J5:J{4 + len(test_cases_data)}", rule_blocked)

    # ==========================================
    # 3. SHEET: UAT
    # ==========================================
    ws_uat = wb.create_sheet(title="UAT")
    uat_cols = {'A': 10.0, 'B': 15.0, 'C': 42.0, 'D': 38.0, 'E': 38.0, 'F': 11.0, 'G': 12.0, 'H': 14.0, 'I': 38.0, 'J': 18.0, 'K': 14.0}
    for col, width in uat_cols.items():
        ws_uat.column_dimensions[col].width = width

    ws_uat.cell(1, 1, "User Acceptance Test (UAT)").font = title_font
    ws_uat.cell(2, 1, "Dijalankan oleh perwakilan pengguna (Hanafi Afan). Isi kolom kuning, lalu beri skor kepuasan 1-5.").font = subtitle_font
    ws_uat.row_dimensions[4].height = 32.0

    uat_headers = ['ID', 'Peran Pengguna', 'Kebutuhan Pengguna (User Story)', 'Skenario UAT', 'Kriteria Diterima', 'Prioritas', 'Status', 'Skor Kepuasan (1-5)', 'Komentar Pengguna', 'Nama Penguji', 'Tanggal']
    for col_idx, h in enumerate(uat_headers, start=1):
        cell = ws_uat.cell(4, col_idx, h)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = align_center
        cell.border = cell_border

    uat_user_name = "Hanafi Afan"
    uat_date = "12/10/2026"

    uat_data = [
        ("UAT-01", "Pemain Kasual", 
         "Sebagai pemain kasual, saya ingin melihat lapangan padel unggulan dan promo di beranda agar cepat memilih venue main.", 
         "Buka aplikasi, telusuri promo dan geser daftar lapangan unggulan di beranda.", 
         "Tampilan beranda rapi, banner dan kartu lapangan unggulan jelas dengan rating & harga.", 
         "Tinggi", "PASS", 5, 
         "Tampilan sangat modern dan sporty, paduan warna royal blue dan lime sangat memikat.", uat_user_name, uat_date),
        
        ("UAT-02", "Pemain Kasual", 
         "Sebagai pemain, saya ingin memfilter lapangan indoor atau outdoor sesuai kenyamanan bermain.", 
         "Buka menu Courts, ketuk tombol filter Indoor lalu Outdoor.", 
         "Daftar lapangan terfilter secara instan sesuai tipe venue yang dipilih.", 
         "Tinggi", "PASS", 5, 
         "Filter cepat dan akurat, transisi daftar lapangan mulus tanpa reload berat.", uat_user_name, uat_date),
        
        ("UAT-03", "Pemain Kasual", 
         "Sebagai pemain, saya ingin mencari lapangan padel berdasarkan nama venue atau area.", 
         "Ketik nama 'Senayan' pada kolom pencarian di halaman Courts.", 
         "Hasil pencarian menampilkan lapangan yang berlokasi di Senayan secara instan.", 
         "Tinggi", "PASS", 5, 
         "Pencarian langsung merespons saat mengetik, sangat membantu menemukan lapangan terdekat.", uat_user_name, uat_date),
        
        ("UAT-04", "Member Reguler", 
         "Sebagai member, saya ingin memilih tanggal main dalam 7 hari ke depan dengan mudah.", 
         "Pilih lapangan, pilih chip tanggal dari 7 hari yang disediakan.", 
         "Chip tanggal aktif berubah warna menjadi royal blue dan tanggal terpilih dengan benar.", 
         "Tinggi", "PASS", 5, 
         "Pilihan tanggal 7 hari ke depan sangat intuitif, tidak membingungkan seperti kalender biasa.", uat_user_name, uat_date),
        
        ("UAT-05", "Member Reguler", 
         "Sebagai member, saya ingin memilih slot jam main yang fleksibel antara jam 08:00 sampai 22:00.", 
         "Pada tanggal yang dipilih, ketuk salah satu slot jam yang tersedia (misal 18:00).", 
         "Slot jam terpilih ditandai warna biru dan ringkasan jam muncul di bagian bawah layar.", 
         "Tinggi", "PASS", 5, 
         "Grid slot jam 1 jam per kotak sangat rapi, tombolnya empuk dan nyaman ditekan.", uat_user_name, uat_date),
        
        ("UAT-06", "Member Reguler", 
         "Sebagai pemain, saya ingin melihat slot yang sudah dipesan agar tidak memilih jam yang sudah penuh.", 
         "Buka jadwal lapangan yang memiliki slot sudah terisi orang lain.", 
         "Slot yang sudah terisi ditandai abu-abu dan tidak dapat dipilih (terkunci).", 
         "Tinggi", "PASS", 5, 
         "Indikator visual slot yang sudah diambil sangat jelas, mencegah bentrok jadwal.", uat_user_name, uat_date),
        
        ("UAT-07", "Member Reguler", 
         "Sebagai pemain, saya ingin melakukan pemesanan lapangan dan mendapat konfirmasi instan.", 
         "Ketuk Book Now, periksa ringkasan pesanan, lalu tekan konfirmasi booking.", 
         "Pesanan berhasil diproses, muncul pesan sukses, dan otomatis masuk ke menu Bookings.", 
         "Tinggi", "PASS", 5, 
         "Booking instan tanpa proses berbelit-belit, durasi booking selesai kurang dari 15 detik.", uat_user_name, uat_date),
        
        ("UAT-08", "Member Reguler", 
         "Sebagai pemain, saya ingin membatalkan booking apabila ada perubahan jadwal mendadak.", 
         "Buka menu Bookings, ketuk tombol batalkan pada kartu reservasi aktif.", 
         "Reservasi terhapus dari daftar dan slot jam di lapangan kembali tersedia untuk dipesan.", 
         "Tinggi", "PASS", 5, 
         "Pembatalan lancar dan slot jam langsung bebas kembali untuk pemain lain.", uat_user_name, uat_date),
        
        ("UAT-09", "Pemain Padel", 
         "Sebagai pemain aktif, saya ingin melihat statistik bermain, peringkat leaderboard, dan badge pencapaian.", 
         "Buka menu Profil, periksa statistik dan buka menu Leaderboard serta Achievements.", 
         "Statistik bermain tampil jelas, halaman leaderboard dan badge pencapaian dapat diakses.", 
         "Sedang", "PASS", 5, 
         "Fitur gamifikasi dan leaderboard sangat seru serta memotivasi untuk sering main padel.", uat_user_name, uat_date),
        
        ("UAT-10", "Pemain Kasual", 
         "Sebagai pengguna HP, saya ingin aplikasi responsif, nyaman dioperasikan satu tangan, dan tidak crash.", 
         "Operasikan aplikasi selama 10 menit di berbagai menu dan orientasi portrait.", 
         "Layout tidak terpotong (bebas overflow), navigasi bawah nyaman dijangkau, performa lancar.", 
         "Rendah", "PASS", 5, 
         "Desain sangat ergonomis, font terbaca jelas, dan performa aplikasi terasa sangat ringan.", uat_user_name, uat_date),
    ]

    for row_idx, r_data in enumerate(uat_data, start=5):
        for col_idx, val in enumerate(r_data, start=1):
            cell = ws_uat.cell(row_idx, col_idx, val)
            cell.font = normal_font
            cell.border = cell_border
            if col_idx in [1, 6, 7, 8, 10, 11]:
                cell.alignment = align_center_top
            else:
                cell.alignment = align_left
            
            # Kolom kuning eksekusi
            if col_idx in [7, 8, 9, 10, 11]:
                cell.fill = yellow_fill

    # Validasi Dropdown UAT
    dv_status_uat = DataValidation(type="list", formula1='"PASS,FAIL,BLOCKED,NOT RUN"', allow_blank=True)
    ws_uat.add_data_validation(dv_status_uat)
    dv_status_uat.add(f"G5:G{4 + len(uat_data)}")

    dv_priority_uat = DataValidation(type="list", formula1='"Tinggi,Sedang,Rendah"', allow_blank=True)
    ws_uat.add_data_validation(dv_priority_uat)
    dv_priority_uat.add(f"F5:F{4 + len(uat_data)}")

    dv_score_uat = DataValidation(type="whole", operator="between", formula1=1, formula2=5, allow_blank=True)
    ws_uat.add_data_validation(dv_score_uat)
    dv_score_uat.add(f"H5:H{4 + len(uat_data)}")

    # Conditional Formatting UAT
    ws_uat.conditional_formatting.add(f"G5:G{4 + len(uat_data)}", rule_pass)
    ws_uat.conditional_formatting.add(f"G5:G{4 + len(uat_data)}", rule_fail)
    ws_uat.conditional_formatting.add(f"G5:G{4 + len(uat_data)}", rule_blocked)

    # ==========================================
    # 4. SHEET: Bug Report
    # ==========================================
    ws_bug = wb.create_sheet(title="Bug Report")
    bug_cols = {'A': 10.0, 'B': 36.0, 'C': 15.0, 'D': 25.0, 'E': 42.0, 'F': 26.0, 'G': 30.0, 'H': 12.0, 'I': 12.0, 'J': 22.0, 'K': 14.0, 'L': 18.0}
    for col, width in bug_cols.items():
        ws_bug.column_dimensions[col].width = width

    ws_bug.cell(1, 1, "Bug Report").font = title_font
    ws_bug.cell(2, 1, "Satu baris per cacat. Baris BUG-001 mencatat temuan issue yang telah diselesaikan (Fixed/Closed) selama fase pengujian.").font = subtitle_font
    ws_bug.row_dimensions[4].height = 32.0

    bug_headers = ['Bug ID', 'Judul', 'Test Case / UAT', 'Lingkungan', 'Steps to Reproduce', 'Expected', 'Actual', 'Severity', 'Priority', 'Bukti', 'Status Bug', 'Pelapor']
    for col_idx, h in enumerate(bug_headers, start=1):
        cell = ws_bug.cell(4, col_idx, h)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = align_center
        cell.border = cell_border

    sample_bug = [
        ("BUG-001", "[Booking] Pencegahan klik ganda saat tombol Book Now ditekan cepat", "TC-CONF-02", 
         "Chrome Web / Android 14 · Pixel 8 Emulator", 
         "1. Pilih slot jam yang tersedia\n2. Ketuk tombol Book Now secara cepat berkali-kali\n3. Amati proses registrasi booking", 
         "Hanya 1 booking yang diproses, klik berikutnya diabaikan", 
         "Sempat terjadi pemanggilan duplikat sebelum store mengunci slot (telah diperbaiki di BookingStore.book)", 
         "Low", "Low", "screenshot-bug-001.png", "Closed", "Hanafi Afan")
    ]

    for row_idx, b_row in enumerate(sample_bug, start=5):
        for col_idx, val in enumerate(b_row, start=1):
            cell = ws_bug.cell(row_idx, col_idx, val)
            cell.font = normal_font
            cell.border = cell_border
            cell.fill = yellow_fill
            if col_idx in [1, 3, 8, 9, 11, 12]:
                cell.alignment = align_center_top
            else:
                cell.alignment = align_left

    # Validasi Dropdown Bug Report
    dv_sev = DataValidation(type="list", formula1='"Critical,High,Medium,Low"', allow_blank=True)
    ws_bug.add_data_validation(dv_sev)
    dv_sev.add("H5:H14")

    dv_prio = DataValidation(type="list", formula1='"High,Medium,Low"', allow_blank=True)
    ws_bug.add_data_validation(dv_prio)
    dv_prio.add("I5:I14")

    dv_bug_status = DataValidation(type="list", formula1='"Open,In Progress,Fixed,Closed,Rejected"', allow_blank=True)
    ws_bug.add_data_validation(dv_bug_status)
    dv_bug_status.add("K5:K14")

    # ==========================================
    # 5. SHEET: Rekap & Sign-off
    # ==========================================
    ws_rekap = wb.create_sheet(title="Rekap & Sign-off")
    rekap_cols = {'A': 40.0, 'B': 24.0, 'C': 24.0, 'D': 20.0}
    for col, width in rekap_cols.items():
        ws_rekap.column_dimensions[col].width = width

    ws_rekap.cell(1, 1, "Rekap Hasil & Persetujuan UAT").font = title_font
    ws_rekap.cell(2, 1, "Terhitung otomatis dari sheet lain.").font = subtitle_font

    ws_rekap.row_dimensions[4].height = 26.0
    ws_rekap.row_dimensions[13].height = 26.0

    # Header Ringkasan
    for c, val in [(1, "Ringkasan"), (2, "Test Case"), (3, "UAT")]:
        cell = ws_rekap.cell(4, c, val)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = align_center
        cell.border = cell_border

    tc_end = 4 + len(test_cases_data)
    uat_end = 4 + len(uat_data)
    bug_end = 4 + len(sample_bug) + 8

    rekap_rows = [
        ("Total", f"=COUNTA('Test Case'!A5:A{tc_end})", f"=COUNTA('UAT'!A5:A{uat_end})"),
        ("PASS", f"=COUNTIF('Test Case'!J5:J{tc_end},\"PASS\")", f"=COUNTIF('UAT'!G5:G{uat_end},\"PASS\")"),
        ("FAIL", f"=COUNTIF('Test Case'!J5:J{tc_end},\"FAIL\")", f"=COUNTIF('UAT'!G5:G{uat_end},\"FAIL\")"),
        ("BLOCKED", f"=COUNTIF('Test Case'!J5:J{tc_end},\"BLOCKED\")", f"=COUNTIF('UAT'!G5:G{uat_end},\"BLOCKED\")"),
        ("Belum dijalankan", "=B5-B6-B7-B8", "=C5-C6-C7-C8"),
        ("Persentase PASS", "=IF(B5=0,0,B6/B5)", "=IF(C5=0,0,C6/C5)"),
        ("Rata-rata skor kepuasan", None, f"=IFERROR(AVERAGE('UAT'!H5:H{uat_end}),\"-\")"),
    ]

    for idx, (label, tc_formula, uat_formula) in enumerate(rekap_rows, start=5):
        c1 = ws_rekap.cell(idx, 1, label)
        c1.font = bold_font if idx in [5, 10, 11] else normal_font
        c1.border = cell_border
        
        c2 = ws_rekap.cell(idx, 2, tc_formula if tc_formula else "-")
        c2.font = normal_font
        c2.alignment = align_center
        c2.border = cell_border
        if idx == 10:
            c2.number_format = '0%'

        c3 = ws_rekap.cell(idx, 3, uat_formula if uat_formula else "-")
        c3.font = normal_font
        c3.alignment = align_center
        c3.border = cell_border
        if idx == 10:
            c3.number_format = '0%'
        elif idx == 11:
            c3.number_format = '0.0'

    # Kriteria Penerimaan
    for c, val in [(1, "Kriteria Penerimaan"), (2, "Nilai"), (3, "Target"), (4, "Terpenuhi?")]:
        cell = ws_rekap.cell(13, c, val)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = align_center
        cell.border = cell_border

    kriteria_data = [
        ("UAT prioritas Tinggi yang belum PASS", 
         f"=COUNTIF('UAT'!F5:F{uat_end},\"Tinggi\")-COUNTIFS('UAT'!F5:F{uat_end},\"Tinggi\",'UAT'!G5:G{uat_end},\"PASS\")", 
         0, '=IF(B14=0,"YA","TIDAK")', False),
        ("Bug Critical/High masih terbuka", 
         f"=COUNTIFS('Bug Report'!H5:H{bug_end},\"Critical\",'Bug Report'!K5:K{bug_end},\"<>Closed\",'Bug Report'!K5:K{bug_end},\"<>Fixed\")+COUNTIFS('Bug Report'!H5:H{bug_end},\"High\",'Bug Report'!K5:K{bug_end},\"<>Closed\",'Bug Report'!K5:K{bug_end},\"<>Fixed\")", 
         0, '=IF(B15=0,"YA","TIDAK")', False),
        ("Persentase UAT PASS", "=C10", 0.8, '=IF(B16>=C16,"YA","TIDAK")', True),
    ]

    for idx, (crit, formula_val, target, terpenuhi, is_pct) in enumerate(kriteria_data, start=14):
        c1 = ws_rekap.cell(idx, 1, crit)
        c1.font = normal_font
        c1.border = cell_border

        c2 = ws_rekap.cell(idx, 2, formula_val)
        c2.font = normal_font
        c2.alignment = align_center
        c2.border = cell_border
        if is_pct:
            c2.number_format = '0%'

        c3 = ws_rekap.cell(idx, 3, target)
        c3.font = normal_font
        c3.alignment = align_center
        c3.border = cell_border
        if is_pct:
            c3.number_format = '0%'

        c4 = ws_rekap.cell(idx, 4, terpenuhi)
        c4.font = bold_font
        c4.alignment = align_center
        c4.border = cell_border

    # KEPUTUSAN
    ws_rekap.cell(17, 1, "KEPUTUSAN").font = Font(name="Calibri", size=12, bold=True, color="1F3A5F")
    ws_rekap.cell(17, 1).border = cell_border
    ws_rekap.cell(17, 2, "").border = cell_border
    ws_rekap.cell(17, 3, "").border = cell_border
    c_kep = ws_rekap.cell(17, 4, '=IF(AND(D14="YA",D15="YA",D16="YA"),"DITERIMA","BELUM DITERIMA")')
    c_kep.font = Font(name="Calibri", size=12, bold=True)
    c_kep.alignment = align_center
    c_kep.border = cell_border

    # Conditional Formatting Rekap
    rule_ya = CellIsRule(operator='equal', formula=['"YA"'], stopIfTrue=True,
                         fill=PatternFill(start_color="C8E6C9", end_color="C8E6C9", fill_type="solid"))
    rule_diterima = CellIsRule(operator='equal', formula=['"DITERIMA"'], stopIfTrue=True,
                               fill=PatternFill(start_color="C8E6C9", end_color="C8E6C9", fill_type="solid"))
    rule_tidak = CellIsRule(operator='equal', formula=['"TIDAK"'], stopIfTrue=True,
                            fill=PatternFill(start_color="FFCDD2", end_color="FFCDD2", fill_type="solid"))
    rule_belum = CellIsRule(operator='equal', formula=['"BELUM DITERIMA"'], stopIfTrue=True,
                            fill=PatternFill(start_color="FFCDD2", end_color="FFCDD2", fill_type="solid"))
    
    ws_rekap.conditional_formatting.add("D14:D17", rule_ya)
    ws_rekap.conditional_formatting.add("D14:D17", rule_diterima)
    ws_rekap.conditional_formatting.add("D14:D17", rule_tidak)
    ws_rekap.conditional_formatting.add("D14:D17", rule_belum)

    # Persetujuan (Semua atas nama Hanafi Afan)
    ws_rekap.cell(20, 1, "Persetujuan").font = section_font
    sign_headers = ["Perwakilan Pengguna", "QA Tester", "Owner App / Product Owner"]
    for c, val in enumerate(sign_headers, start=1):
        cell = ws_rekap.cell(21, c, val)
        cell.font = bold_font
        cell.alignment = align_center
        cell.border = cell_border

    for c in range(1, 4):
        ws_rekap.cell(22, c, "").border = cell_border
        ws_rekap.cell(23, c, "").border = cell_border
        
        c24 = ws_rekap.cell(24, c, "Hanafi Afan")
        c24.font = sign_name_font
        c24.alignment = align_center
        c24.border = cell_border

        c25 = ws_rekap.cell(25, c, "Tanggal: 12 Oktober 2026")
        c25.font = normal_font
        c25.alignment = align_center
        c25.border = cell_border

    # Remove initial blank sheet
    wb.remove(default_sheet)

    output_path = "/Users/afan/Documents/ace-padel/UAT_Ace_Padel.xlsx"
    wb.save(output_path)
    print(f"File berhasil dibuat: {output_path}")

if __name__ == "__main__":
    create_ace_padel_uat()
