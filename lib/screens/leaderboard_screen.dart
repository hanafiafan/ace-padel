import '../core/widgets/ap_shape.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/widgets/ap_decor.dart';
import '../core/widgets/responsive_container.dart';
import 'dart:async';
import '../core/utils/ui.dart';
import '../data.dart';
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';

enum LeaderboardScope { global, friends }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  LeaderboardScope _scope = LeaderboardScope.global;

  @override
  void initState() {
    super.initState();
    FriendStore.instance.refresh(); // GET /leaderboard (+ friends when logged in)
  }

  void _showAddFriendsSheet(BuildContext context) {
    if (!requireLogin(context, 'menambah teman')) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AP.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _AddFriendsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: SafeArea(
        child: AnimatedBuilder(
        animation: FriendStore.instance,
        builder: (context, _) {
          final friendStore = FriendStore.instance;
          final List<Player> displayed = _scope == LeaderboardScope.global
              ? friendStore.globalBoard
              : friendStore.friendsBoard;

          final meIndex = displayed.indexWhere((p) => p.isMe);

          return APList(
            onRefresh: friendStore.refresh,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Header with Title and Tambah Teman button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'Leaderboard',
                          style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                            fontSize: 24.64,
                            fontWeight: FontWeight.w800,
                            color: AP.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _scope == LeaderboardScope.global
                              ? 'Musim ini • Ranking Global'
                              : 'Musim ini • Ranking Teman',
                          style:  TextStyle(color: AP.slate, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFriendsSheet(context),
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: const Text(
                      'Tambah Teman',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AP.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: ChamferBorder(br: 10, tl: 10),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Segmented Scope Toggle: [ Global | Teman ]
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AP.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AP.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _scopeTab(
                        title: 'Global',
                        icon: LucideIcons.globe,
                        count: friendStore.globalBoard.length,
                        selected: _scope == LeaderboardScope.global,
                        onTap: () =>
                            setState(() => _scope = LeaderboardScope.global),
                      ),
                    ),
                    Expanded(
                      child: _scopeTab(
                        title: 'Teman',
                        icon: LucideIcons.users,
                        count: friendStore.friendIds.length,
                        selected: _scope == LeaderboardScope.friends,
                        onTap: () =>
                            setState(() => _scope = LeaderboardScope.friends),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content based on scope & player count
              if (displayed.isEmpty)
                _buildEmptyFriendsState()
              else ...[
                // Top 3 Podium (if at least 3 players available)
                if (displayed.length >= 3) ...[
                  _Podium(topThree: displayed.take(3).toList()),
                  const SizedBox(height: 20),
                ],

                // "Kamu" rank badge if logged-in player is in the list
                if (meIndex >= 0) ...[
                  _MyRankCard(
                    rank: meIndex + 1,
                    player: displayed[meIndex],
                    scopeLabel: _scope == LeaderboardScope.global
                        ? 'Ranking Global'
                        : 'Ranking di Antara Teman',
                  ),
                  const SizedBox(height: 16),
                ],

                // List of players
                if (displayed.length >= 3)
                  ...displayed.skip(3).map((p) {
                    final rank = displayed.indexOf(p) + 1;
                    return _RankRow(
                      rank: rank,
                      player: p,
                      isFriend: friendStore.isFriend(p.id),
                      onToggleFriend: () => _toggleFriendWithSnack(p),
                    );
                  })
                else
                  ...displayed.map((p) {
                    final rank = displayed.indexOf(p) + 1;
                    return _RankRow(
                      rank: rank,
                      player: p,
                      isFriend: friendStore.isFriend(p.id),
                      onToggleFriend: () => _toggleFriendWithSnack(p),
                    );
                  }),

                // Extra invite banner when in Friends view
                if (_scope == LeaderboardScope.friends) ...[
                  const SizedBox(height: 16),
                  _buildInviteMoreBanner(),
                ],
              ],
            ],
          );
        },
      ),
    ),
  );
}

  Future<void> _toggleFriendWithSnack(Player p) async {
    if (!requireLogin(context, 'menambah teman')) return;
    try {
      final willAdd = await FriendStore.instance.toggleFriend(p);
      if (!mounted) return;
      showInfo(context, willAdd
          ? '${p.name} berhasil ditambahkan ke daftar teman!'
          : '${p.name} dihapus dari daftar teman.');
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Widget _scopeTab({
    required String title,
    required IconData icon,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AP.blueDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AP.lime : AP.slate,
            ),
            const SizedBox(width: 6),
            Text(
              '$title ($count)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? Colors.white : AP.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AP.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AP.line),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AP.lime.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child:  Icon(LucideIcons.users, size: 48, color: AP.ink),
          ),
          const SizedBox(height: 16),
           Text(
            'Belum Ada Teman di Leaderboard',
            style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
              fontWeight: FontWeight.w800,
              fontSize: 19.55,
              color: AP.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
           Text(
            'Tambahkan pemain lain ke daftar teman untuk melihat perbandingan skor & bersaing bersama!',
            style: TextStyle(color: AP.slate, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddFriendsSheet(context),
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text(
              'Cari & Tambah Teman Sekarang',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AP.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: ChamferBorder(br: 10, tl: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteMoreBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AP.lime.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AP.lime),
      ),
      child: Row(
        children: [
           Icon(LucideIcons.trophy, color: AP.ink, size: 28),
          const SizedBox(width: 12),
           Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajak Teman Lainnya!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AP.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tambah lebih banyak lawan tanding untuk memanaskan persaingan ranking mingguan.',
                  style: TextStyle(color: AP.slate, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showAddFriendsSheet(context),
            style: TextButton.styleFrom(
              foregroundColor: AP.onLime,
              backgroundColor: AP.lime,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: ChamferBorder(br: 10, tl: 10),
            ),
            child: const Text(
              '+ Teman',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= MODAL TAMBAH TEMAN ================= //
class _AddFriendsModal extends StatefulWidget {
  const _AddFriendsModal();

  @override
  State<_AddFriendsModal> createState() => _AddFriendsModalState();
}

class _AddFriendsModalState extends State<_AddFriendsModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;
  List<Player>? _results; // null = show top players from the leaderboard
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// GET /players/search?q= (debounced).
  void _onQuery(String val) {
    setState(() => _query = val);
    _debounce?.cancel();
    if (val.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _searching = true);
      try {
        final r = await FriendStore.instance.search(val.trim());
        if (mounted && _query == val) setState(() => _results = r);
      } on ApiException catch (e) {
        if (mounted) showError(context, e);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendStore = FriendStore.instance;
    final filtered = _results ?? friendStore.globalBoard.where((p) => !p.isMe).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AP.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Tambah Teman Pemain',
                style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                  fontWeight: FontWeight.w800,
                  fontSize: 20.7,
                  color: AP.ink,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
           Text(
            'Cari pemain padel untuk dimasukkan ke leaderboard teman Anda.',
            style: TextStyle(color: AP.slate, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Search Field
          TextField(
            controller: _searchCtrl,
            onChanged: _onQuery,
            decoration: InputDecoration(
              hintText: 'Cari nama atau @username pemain...',
              hintStyle:  TextStyle(fontSize: 13, color: AP.slate),
              prefixIcon:  Icon(LucideIcons.search, color: AP.slate, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AP.cloud,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Daftar Pemain:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),

          // Players List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _searching
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()))
                : filtered.isEmpty
                ?  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Pemain tidak ditemukan.',
                        style: TextStyle(color: AP.slate),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                         Divider(height: 12, color: AP.line),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final isFriend = friendStore.isFriend(p.id);

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AP.blue,
                            child: Text(
                              p.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style:  TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AP.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${p.handle} • ${p.points} pts',
                                  style:  TextStyle(
                                    color: AP.slate,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                final added = await friendStore.toggleFriend(p);
                                if (!mounted) return;
                                setState(() {});
                                showInfo(context, added
                                    ? '${p.name} ditambahkan ke teman!'
                                    : '${p.name} dihapus dari teman.');
                              } on ApiException catch (e) {
                                if (mounted) showError(context, e);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isFriend ? AP.lime : AP.blue,
                              foregroundColor:
                                  isFriend ? AP.onLime : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: ChamferBorder(br: 10, tl: 10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFriend ? LucideIcons.check : LucideIcons.plus,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFriend ? 'Berteman' : 'Tambah',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ================= PODIUM ================= //
class _Podium extends StatelessWidget {
  final List<Player> topThree;
  const _Podium({required this.topThree});

  @override
  Widget build(BuildContext context) {
    // order: 2nd, 1st, 3rd
    final p1 = topThree[0];
    final p2 = topThree.length > 1 ? topThree[1] : null;
    final p3 = topThree.length > 2 ? topThree[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (p2 != null)
          Expanded(child: _PodiumItem(player: p2, rank: 2, height: 120))
        else
          const Spacer(),
        const SizedBox(width: 10),
        Expanded(child: _PodiumItem(player: p1, rank: 1, height: 150)),
        const SizedBox(width: 10),
        if (p3 != null)
          Expanded(child: _PodiumItem(player: p3, rank: 3, height: 96))
        else
          const Spacer(),
      ],
    );
  }
}

const _medal = {
  1: Color(0xFFF5B301),
  2: Color(0xFFB7C0D8),
  3: Color(0xFFCD7F32),
};

class _PodiumItem extends StatelessWidget {
  final Player player;
  final int rank;
  final double height;
  const _PodiumItem(
      {required this.player, required this.rank, required this.height});

  @override
  Widget build(BuildContext context) {
    final medal = _medal[rank]!;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: rank == 1 ? 72 : 60,
              height: rank == 1 ? 72 : 60,
              decoration: BoxDecoration(
                color: AP.blue,
                shape: BoxShape.circle,
                border: Border.all(color: medal, width: 3),
                boxShadow: rank == 1
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFF5B301).withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(player.initials,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: rank == 1 ? 22 : 18)),
            ),
            if (rank == 1)
              const Positioned(
                top: -18,
                child: Icon(LucideIcons.trophy,
                    color: Color(0xFFF5B301), size: 26),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(player.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          height: height,
          decoration:  BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AP.blue, AP.blueDark],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Text('$rank',
                  style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                      color: medal, fontSize: 26.88, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '${player.points}',
                  key: ValueKey('${player.id}_${player.points}'),
                  style: const TextStyle(
                      color: AP.lime, fontWeight: FontWeight.w800),
                ),
              ),
              const Text('pts',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

// ================= MY RANK CARD ================= //
class _MyRankCard extends StatelessWidget {
  final int rank;
  final Player player;
  final String scopeLabel;
  const _MyRankCard({
    required this.rank,
    required this.player,
    this.scopeLabel = 'Ranking Kamu',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:  LinearGradient(colors: [AP.blueDark, AP.blue]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#$rank',
                style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                    color: AP.lime, fontWeight: FontWeight.w800, fontSize: 18.4)),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            backgroundColor: AP.lime,
            child: Text(player.initials,
                style:  TextStyle(
                    color: AP.onLime, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Kamu',
                        style: TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18.4)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AP.lime.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          scopeLabel,
                          style: const TextStyle(
                              color: AP.lime,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                Text('${player.wins} menang • ${player.matches} main',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${player.points}',
                  style: const TextStyle(fontFamily: 'Display', fontStyle: FontStyle.italic, 
                      color: AP.lime,
                      fontWeight: FontWeight.w800,
                      fontSize: 20.7)),
              const Text('poin',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= RANK ROW ================= //
class _RankRow extends StatelessWidget {
  final int rank;
  final Player player;
  final bool isFriend;
  final VoidCallback onToggleFriend;

  const _RankRow({
    required this.rank,
    required this.player,
    required this.isFriend,
    required this.onToggleFriend,
  });

  @override
  Widget build(BuildContext context) {
    final me = player.isMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: me ? AP.lime.withValues(alpha: .25) : AP.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: me ? AP.lime : AP.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style:
                   TextStyle(fontWeight: FontWeight.w800, color: AP.slate),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: me ? AP.blueDark : AP.blue,
            child: Text(
              player.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (isFriend && !me) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AP.lime.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child:  Text(
                          'Teman',
                          style: TextStyle(
                            color: AP.ink,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${player.wins} menang • ${player.handle}',
                  style:  TextStyle(color: AP.slate, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quick friend toggle button for others
          if (!me) ...[
            GestureDetector(
              onTap: onToggleFriend,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFriend
                      ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                      : AP.cloud,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFriend
                        ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                        : AP.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFriend ? LucideIcons.check : LucideIcons.userPlus,
                      size: 13,
                      color: isFriend ? const Color(0xFF16A34A) : AP.blue,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isFriend ? 'Teman' : '+ Teman',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isFriend ? const Color(0xFF16A34A) : AP.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          Text(
            '${player.points}',
            style:  TextStyle(
              color: AP.blue,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
