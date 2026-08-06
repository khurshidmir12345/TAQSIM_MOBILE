import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Fon rejimidagi xabarlar uchun kirish nuqtasi.
///
/// Tizim bildirishnomani o'zi ko'rsatadi, shuning uchun bu yerda ish yo'q —
/// lekin handler ro'yxatdan o'tkazilmasa Firebase ogohlantirish beradi.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {}

/// FCM push: ruxsat, token va xabarlarni ko'rsatish.
///
/// Ilova **ochiq** turganda tizim bildirishnomani avtomatik ko'rsatmaydi
/// (Android'da), shuning uchun uni `flutter_local_notifications` orqali
/// o'zimiz chiqaramiz.
class PushService {
  PushService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'taqseem_default',
    'Bildirishnomalar',
    description: 'TAQSEEM bildirishnomalari',
    importance: Importance.high,
  );

  static bool _initialized = false;

  /// Bildirishnoma bosilganda chaqiriladi (ilova ichida yo'naltirish uchun).
  static VoidCallback? onOpened;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Ruxsatni FirebaseMessaging so'raydi — ikki marta so'ralmasin.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onOpened?.call(),
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // iOS: ilova ochiq turganda ham banner ko'rinsin.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => onOpened?.call());
  }

  /// Bildirishnoma ruxsatini so'raydi (iOS va Android 13+).
  static Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// FCM qurilma tokeni.
  ///
  /// iOS'da APNs tokeni tayyor bo'lmaguncha `getToken()` `null` qaytaradi —
  /// shuning uchun bir necha marta qayta uriniladi.
  static Future<String?> token() async {
    try {
      if (Platform.isIOS) {
        var apns = await FirebaseMessaging.instance.getAPNSToken();

        for (var i = 0; i < 5 && apns == null; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
          apns = await FirebaseMessaging.instance.getAPNSToken();
        }

        if (apns == null) {
          debugPrint('[push] APNs token hali tayyor emas');

          return null;
        }
      }

      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[push] token olinmadi: $e');

      return null;
    }
  }

  /// Token yangilanganda xabar beradi (Firebase uni vaqti-vaqti bilan almashtiradi).
  static Stream<String> get tokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  static String get platform => Platform.isIOS ? 'ios' : 'android';

  static Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
