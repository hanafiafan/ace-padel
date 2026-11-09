import '../core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../core/utils/haptics.dart';
import '../core/widgets/responsive_container.dart';
import '../data.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'booking_screen.dart';

class CourtsScreen extends StatefulWidget {
  const CourtsScreen({super.key});

  @override
  State<CourtsScreen> createState() => _CourtsScreenState();
}

class _CourtsScreenState extends State<CourtsScreen> {
  bool? _indoor; // null = semua
  String? _city; // null = semua kota
  String _sortBy = 'Rekomendasi'; // Rekomendasi, Rating, Harga Terendah, Harga Tertinggi
  String? _requiredFacility;
  final _controller = TextEditingController();
  String _query = '';
  bool _isGridView = false;

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    CatalogStore.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    CatalogStore.instance.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  void _openCourt(Court c) async {
    final booked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(court: c)),
    );
    if (booked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking ${c.name} berhasil!')),
      );
    }
  }

  List<Court> get _filtered {
    final q = _query.trim().toLowerCase();
    var list = courts.where((c) {
      if (_indoor != null && c.indoor != _indoor) return false;
      if (_city != null && c.city != _city) return false;
      if (_requiredFacility != null &&
          !c.facilities.any((f) =>
              f.toLowerCase().contains(_requiredFacility!.toLowerCase()))) {
        return false;
      }
      if (q.isNotEmpty &&
          !(c.name.toLowerCase().contains(q) ||
              c.venue.toLowerCase().contains(q) ||
              c.area.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'Rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Harga Terendah':
        list.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case 'Harga Tertinggi':
        list.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
        break;
      default:
        // Rekomendasi / ID
        break;
    }

    return list;
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AP.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CityPicker(selected: _city),
    );
    if (picked != null) {
      setState(() => _city = picked == '__ALL__' ? null : picked);
    }
  }

  void _showSortFilterSheet() {
    String tempSort = _sortBy;
    String? tempFac = _requiredFacility;

    showModalBottomSheet(
      context: context,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Urutkan',
                    style: TextStyle(fontFamily: 'Display', fontSize: 20.7, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        tempSort = 'Rekomendasi';
                        tempFac = null;
                      });
                    },
                    child: const Text('Reset',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
               Text('Urutkan Berdasarkan',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: AP.slate)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Rekomendasi',
                  'Rating',
                  'Harga Terendah',
                  'Harga Tertinggi',
                ].map((s) {
                  final sel = tempSort == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: sel,
                    onSelected: (val) {
                      if (val) setSheetState(() => tempSort = s);
                    },
                    selectedColor: AP.blue,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : AP.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
               Text('Fasilitas Wajib',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: AP.slate)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Raket',
                  'Shower',
                  'Parkir',
                  'WiFi',
                  'Cafe',
                ].map((fac) {
                  final sel = tempFac == fac;
                  return ChoiceChip(
                    label: Text(fac),
                    selected: sel,
                    onSelected: (val) {
                      setSheetState(() => tempFac = val ? fac : null);
                    },
                    selectedColor: AP.lime,
                    labelStyle: TextStyle(
                      color: sel ? AP.onLime : AP.slate,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _sortBy = tempSort;
                      _requiredFacility = tempFac;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AP.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Terapkan Filter',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    // kota populer untuk chip cepat
    const quick = ['Jakarta', 'Tangerang', 'Badung', 'Denpasar', 'Gianyar'];
    final hasActiveFilter =
        _sortBy != 'Rekomendasi' || _requiredFacility != null;

    return ResponsiveContainer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cari Lapangan',
                      style: TextStyle(fontFamily: 'Display', fontSize: 24.64, fontWeight: FontWeight.w800)),
                  Row(
                    children: [
                      IconButton(
                        tooltip: _isGridView ? 'Tampilan List' : 'Tampilan Grid',
                        icon: Icon(
                          _isGridView ? LucideIcons.list : LucideIcons.layoutGrid,
                          color: APColors.inkSecondary,
                          size: 22,
                        ),
                        onPressed: () {
                          APHaptics.light();
                          setState(() => _isGridView = !_isGridView);
                        },
                      ),
                      IconButton(
                        tooltip: 'Filter & Urutkan',
                        icon: Badge(
                          isLabelVisible: hasActiveFilter,
                          backgroundColor: AP.lime,
                          child:  Icon(LucideIcons.slidersHorizontal, color: AP.blue),
                        ),
                        onPressed: _showSortFilterSheet,
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AP.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AP.line),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau lokasi venue',
                  hintStyle:  TextStyle(color: AP.slate),
                  icon:  Icon(LucideIcons.search, color: AP.slate),
                  border: InputBorder.none,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon:  Icon(LucideIcons.x, color: AP.slate),
                          onPressed: () => setState(() {
                            _controller.clear();
                            _query = '';
                          }),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // City filter row: "Kota" button + quick cities
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _pickCity,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _city != null ? AP.blue : AP.blueDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.building2,
                              color: AP.lime, size: 16),
                          const SizedBox(width: 6),
                          Text(_city ?? 'Pilih kota',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          const Icon(LucideIcons.chevronDown, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  _cityChip('Semua', _city == null, () => setState(() => _city = null)),
                  for (final c in quick)
                    _cityChip(c, _city == c, () => setState(() => _city = c)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Indoor/Outdoor Row
            Row(
              children: [
                _typeFilter('Semua', null),
                const SizedBox(width: 10),
                _typeFilter('Indoor', true),
                const SizedBox(width: 10),
                _typeFilter('Outdoor', false),
                const Spacer(),
                if (_sortBy != 'Rekomendasi')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AP.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _sortBy,
                      style:  TextStyle(
                          color: AP.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${list.length} lapangan ditemukan',
                style:  TextStyle(color: AP.slate, fontSize: 13)),
            const SizedBox(height: 10),
            Expanded(
              child: list.isEmpty
                  ? (CatalogStore.instance.isLoading
                      ? const AppSkeletonList(count: 3, itemHeight: 210)
                      : _empty())
                  : RefreshIndicator(
                      onRefresh: () async {
                        APHaptics.medium();
                        await CatalogStore.instance.refreshCourts();
                      },
                      color: AP.blue,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final useGrid = _isGridView || constraints.maxWidth > 600;
                          if (useGrid) {
                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 24),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 380,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: list.length,
                              itemBuilder: (_, i) => FeaturedCard(
                                court: list[i],
                                onTap: () => _openCourt(list[i]),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: list.length,
                            itemBuilder: (_, i) => CourtRow(
                              court: list[i],
                              onTap: () => _openCourt(list[i]),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(LucideIcons.mapPin, size: 56, color: AP.slate),
            const SizedBox(height: 12),
            const Text('Tidak ada lapangan',
                style: TextStyle(fontFamily: 'Display', fontWeight: FontWeight.w800, fontSize: 18.4)),
            const SizedBox(height: 4),
             Text('Coba kota atau kriteria filter lain.',
                style: TextStyle(color: AP.slate)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _city = null;
                  _indoor = null;
                  _query = '';
                  _sortBy = 'Rekomendasi';
                  _requiredFacility = null;
                  _controller.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AP.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Reset Filter',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Widget _cityChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: selected ? AP.blue : AP.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AP.blue : AP.line),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AP.blue.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AP.ink,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _typeFilter(String label, bool? value) {
    final selected = _indoor == value;
    return GestureDetector(
      onTap: () => setState(() => _indoor = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AP.lime : AP.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AP.lime : AP.line),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AP.lime.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AP.onLime : AP.slate,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CityPicker extends StatefulWidget {
  final String? selected;
  const _CityPicker({this.selected});

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final all = cities;
    final list = q.isEmpty
        ? all
        : all.where((c) => c.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: AP.line, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Pilih Kota / Wilayah',
              style: TextStyle(fontFamily: 'Display', fontSize: 20.7, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Cari kota...',
              hintStyle:  TextStyle(color: AP.slate),
              prefixIcon:  Icon(LucideIcons.search, color: AP.slate),
              filled: true,
              fillColor: AP.cloud,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: APList(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('Semua Kota',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: widget.selected == null
                      ?  Icon(LucideIcons.check, color: AP.blue)
                      : null,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context, '__ALL__');
                  },
                ),
                ...list.map((c) => ListTile(
                      title: Text(c),
                      trailing: widget.selected == c
                          ?  Icon(LucideIcons.check, color: AP.blue)
                          : null,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context, c);
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
