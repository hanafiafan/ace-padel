import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart';

/// Background (terminated/background) FCM handler. Must be a top-level
/// function annotated with `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Keep minimal — the OS already displays the notification payload.
}

/// Push (FCM) + local notifications. Safe to call without Firebase config:
/// every Firebase step is guarded, so the app runs normally and simply
/// skips push when `google-services.json` / `GoogleService-Info.plist`
/// are absent (see FCM_SETUP.md).
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _fcmReady = false;
  bool _localReady = false;

  static const _channel = AndroidNotificationChannel(
    'ace_padel_default',
    'Ace Padel',
    description: 'Pengingat booking, status pembayaran, dan info komunitas.',
    importance: Importance.high,
  );

  /// Call once at startup (after the first frame is fine). Never throws.
  Future<void> init() async {
    await _initLocal();
    await _initFcm();
  }

  // ---------- local notifications ----------
  Future<void> _initLocal() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // app pakai WIB
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _local.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      _localReady = true;
    } catch (e) {
      debugPrint('Local notif init skipped: $e');
    }
  }

  Future<void> showLocal(String title, String body, {String? payload}) async {
    if (!_localReady) return;
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(_channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Schedule a one-off reminder at [when] (local/WIB). Silently ignores
  /// times in the past. [id] must be stable per booking to allow cancel.
  Future<void> scheduleReminder(int id, String title, String body,
      DateTime when) async {
    if (!_localReady) return;
    final at = tz.TZDateTime.from(when, tz.local);
    if (at.isBefore(tz.TZDateTime.now(tz.local))) return;
    try {
      await _local.zonedSchedule(
        id,
        title,
        body,
        at,
        NotificationDetails(
          android: AndroidNotificationDetails(_channel.id, _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleReminder skipped: $e');
    }
  }

  /// Remind the player 60 minutes before the match starts.
  /// [date] = 'YYYY-MM-DD', [slot] = 'HH:mm'.
  Future<void> scheduleBookingReminder({
    required String bookingId,
    required String courtName,
    required String date,
    required String slot,
  }) async {
    DateTime start;
    try {
      final d = date.split('-').map(int.parse).toList();
      final t = slot.split(':').map(int.parse).toList();
      start = DateTime(d[0], d[1], d[2], t[0], t.length > 1 ? t[1] : 0);
    } catch (_) {
      return;
    }
    await scheduleReminder(
      bookingId.hashCode & 0x7fffffff,
      'Match sebentar lagi 🎾',
      '$courtName jam $slot. Siapkan raketmu!',
      start.subtract(const Duration(hours: 1)),
    );
  }

  Future<void> cancelBookingReminder(String bookingId) async {
    if (!_localReady) return;
    try {
      await _local.cancel(bookingId.hashCode & 0x7fffffff);
    } catch (_) {}
  }

  // ---------- FCM ----------
  Future<void> _initFcm() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase not configured, push disabled: $e');
      return; // app continues fine without push
    }
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      // Foreground: show it ourselves via a local notification.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) {
          showLocal(n.title ?? 'Ace Padel', n.body ?? '',
              payload: m.data['route'] as String?);
        }
      });

      final token = await messaging.getToken();
      if (token != null) await ApiService.instance.registerDevice(token);
      messaging.onTokenRefresh
          .listen((t) => ApiService.instance.registerDevice(t));
      _fcmReady = true;
    } catch (e) {
      debugPrint('FCM setup error: $e');
    }
  }

  bool get fcmReady => _fcmReady;
}
