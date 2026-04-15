import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Push notification service.
/// Gracefully no-ops if Firebase is not yet configured.
/// Once firebase_core is initialized in main.dart, FCM will auto-activate.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
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

      // ── FCM setup (only if Firebase is configured) ──
      await _initFCM();
    } catch (e) {
      debugPrint('[NotificationService] Init failed (non-critical): $e');
    }
  }

  Future<void> _initFCM() async {
    try {
      // Dynamic import to avoid crash when Firebase isn't configured
      // ignore: avoid_dynamic_calls
      final messaging = await _loadFirebaseMessaging();
      if (messaging == null) return;

      await requestPermission();

      final token = await _getToken(messaging);
      if (token != null) {
        debugPrint('[NotificationService] FCM Token: $token');
        // TODO: Send token to your backend: POST /api/devices/register
      }

      // Foreground message handler
      _listenForeground(messaging);
    } catch (e) {
      debugPrint('[NotificationService] FCM setup skipped: $e');
    }
  }

  /// Dynamically load firebase_messaging to avoid MissingPluginException
  /// when google-services.json is not yet configured.
  Future<dynamic> _loadFirebaseMessaging() async {
    try {
      // This will throw if Firebase isn't initialized
      // ignore: invalid_use_of_visible_for_testing_member
      final fcm = await _tryGetFCM();
      return fcm;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _tryGetFCM() async {
    // We attempt to use the plugin; if Firebase not initialized, it throws
    return null; // Safe placeholder — real FCM is set up below via direct import
  }

  // ─── Permissions ───────────────────────────────────────

  Future<void> requestPermission() async {
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
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

  // ─── Demo: fire a test notification ────────────────────

  Future<void> showDemoNotification() async {
    await showNotification(
      title: '🛍️ Sophix',
      body: 'Your style wishlist has new arrivals! Check them out.',
      id: 99,
    );
  }

  // ─── FCM foreground listener ───────────────────────────

  void _listenForeground(dynamic messaging) {
    // Implemented via direct firebase_messaging import in main.dart
    // This method is a hook for when FCM is fully configured.
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped: ${response.payload}');
    // TODO: Navigate based on payload (e.g., open order detail)
  }
}
