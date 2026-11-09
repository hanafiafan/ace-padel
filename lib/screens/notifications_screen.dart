import '../core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/utils/ui.dart';
import '../data.dart' show relativeDate;
import '../services/api_service.dart';
import '../store.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationStore.instance;

  @override
  void initState() {
    super.initState();
    if (UserStore.instance.isLoggedIn) _store.refresh();
  }

  Future<void> _markAllRead() async {
    try {
      await _store.markAllRead();
      if (mounted) showInfo(context, 'Semua notifikasi ditandai telah dibaca.');
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  static (IconData, Color) _style(String type) {
    switch (type) {
      case 'booking':
        return (LucideIcons.clock, AP.blue);
      case 'payment':
        return (LucideIcons.badgeCheck, const Color(0xFF16A34A));
      case 'match':
        return (LucideIcons.users, AP.blue);
      case 'friend':
        return (LucideIcons.userPlus, AP.blue);
      case 'coach':
        return (LucideIcons.medal, const Color(0xFFF5B301));
      default:
        return (LucideIcons.bell, AP.slate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AP.cloud,
      appBar: AppBar(
        backgroundColor: AP.cloud,
        elevation: 0,
        foregroundColor: AP.ink,
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child:  Text(
              'Tandai dibaca',
              style: TextStyle(color: AP.blue, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_store, UserStore.instance]),
        builder: (context, _) {
          if (!UserStore.instance.isLoggedIn) {
            return _centerNote('Masuk untuk melihat notifikasi Anda.',
                action: TextButton(onPressed: () => requireLogin(context, 'melihat notifikasi'), child: const Text('Masuk')));
          }
          if (_store.isLoading && _store.items.isEmpty) {
            return const Padding(padding: EdgeInsets.all(16), child: AppSkeletonList(count: 6, itemHeight: 84));
          }
          if (_store.error != null && _store.items.isEmpty) {
            return _centerNote(_store.error!, action: TextButton(onPressed: _store.refresh, child: const Text('Coba lagi')));
          }
          if (_store.items.isEmpty) return _centerNote('Belum ada notifikasi.');
          return RefreshIndicator(
            onRefresh: _store.refresh,
            child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemCount: _store.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = _store.items[i];
          final (icon, color) = _style(item.type);
          final n = {
            'title': item.title,
            'body': item.body,
            'time': relativeDate(item.createdAt?.toIso8601String()),
            'icon': icon,
            'color': color,
            'unread': !item.read,
          };
          final unread = n['unread'] as bool;
          return GestureDetector(
            onTap: unread ? () => _store.markRead(item) : null,
            child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AP.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unread ? AP.blue.withValues(alpha: 0.4) : AP.line,
                width: unread ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (n['color'] as Color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    n['icon'] as IconData,
                    color: n['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              n['title'] as String,
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 15,
                                color: AP.ink,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration:  BoxDecoration(
                                color: AP.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n['body'] as String,
                        style:  TextStyle(
                          color: AP.slate,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n['time'] as String,
                        style: TextStyle(
                          color: AP.slate.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
          );
        },
      ),
    );
  }

  Widget _centerNote(String msg, {Widget? action}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bellOff, size: 40, color: AP.slate),
              const SizedBox(height: 12),
              Text(msg, textAlign: TextAlign.center, style: TextStyle(color: AP.slate)),
              if (action != null) action,
            ],
          ),
        ),
      );
}
