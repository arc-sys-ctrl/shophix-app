import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sophix_mobile/config/env_config.dart';


/// Push notification service.
/// Now fully connected to Firebase and the Sophix Backend.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();

  bool _initialized = false;

  // ─── Android notification channel ──────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sophix_high_importance',
    'Sophix Notifications',
    description: 'Order updates, promotions and style alerts from Sophix.',
    importance: Importance.high,
    playSound: true,
  );

  /// Call this from main() after WidgetsFlutterBinding.ensureInitialized()
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // ── Local notifications setup ──
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        linux: linuxSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create Android channel
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      _initialized = true;
      debugPrint('[NotificationService] Local notifications initialized.');

      // FCM + token sync are mobile targets; Linux/Windows desktop embedders often
      // lack full Firebase Messaging support and can crash or drop the connection.
      if (Platform.isAndroid || Platform.isIOS) {
        await _initFCM();
      } else {
        debugPrint('[NotificationService] FCM skipped on ${Platform.operatingSystem}.');
      }
    } catch (e) {
      debugPrint('[NotificationService] Init failed (non-critical): $e');
    }
  }

  Future<void> _initFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permissions (especially for iOS and Android 13+)
      await requestPermission();

      // Get current token and sync
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[NotificationService] FCM Token: $token');
        await syncTokenToBackend(token);
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        syncTokenToBackend(newToken);
      });

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Foreground message received: ${message.notification?.title}');

        final notification = message.notification;
        // Show on both Android and iOS when FCM includes a notification payload (Android-only check hid iOS).
        if (notification != null) {
          showNotification(
            title: notification.title ?? '',
            body: notification.body ?? '',
            payload: jsonEncode(message.data),
          );
        }
      });

      // Setup opened app from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] App opened via notification: ${message.messageId}');
      });

    } catch (e) {
      debugPrint('[NotificationService] FCM setup skipped or failed: $e');
    }
  }

  /// Syncs the FCM token with the Sophix Backend to enable targeted push
  Future<void> syncTokenToBackend(String token) async {
    try {
      // Get the current user session token
      final userToken = await _storage.read(key: 'token');
      if (userToken == null) {
        debugPrint('[NotificationService] No user token found, skipping backend sync.');
        return;
      }

      // Backend endpoint we created in the production phase
      final response = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/devices/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': Platform.operatingSystem,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[NotificationService] FCM token registered with backend.');
      } else {
        debugPrint('[NotificationService] Backend sync failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('[NotificationService] Backend sync error: $e');
    }
  }

  // ─── Permissions ───────────────────────────────────────

  Future<void> requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (_) {}
  }

  // ─── Show a local notification ─────────────────────────

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'sophix_high_importance',
      'Sophix Notifications',
      channelDescription: 'Order updates, promotions and style alerts from Sophix.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> showDemoNotification() async {
    await showNotification(
      title: '🛍️ Sophix',
      body: 'Your style wishlist has new arrivals! Check them out.',
      id: 99,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped: ${response.payload}');
  }
}
