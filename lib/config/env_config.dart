import 'package:flutter/foundation.dart';

/// Environment-aware configuration for the Sophix mobile app.
class EnvConfig {
  /// Toggle this to change between local development and production.
  static const bool isProduction = kReleaseMode;

  /// Full API base including `/api`, e.g. `http://192.168.1.10:5000/api` for a phone on the same LAN.
  /// Run: `flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:5000/api`
  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// The base URL for the Sophix backend API.
  /// Update the production URL once you have a live domain or static IP.
  static String get baseUrl {
    if (isProduction) {
      // TODO: Replace with your actual production domain
      return 'https://api.sophix-luxury.com/api';
    }
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      var u = override.replaceAll(RegExp(r'/+$'), '');
      return u.endsWith('/api') ? u : '$u/api';
    }
    // Local dev: Android emulator → host loopback; physical device → use dart-define above.
    final String host = kIsWeb
        ? 'localhost'
        : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');
    return 'http://$host:5000/api';
  }

  static String get authUrl => '$baseUrl/auth';
  static String get productsUrl => '$baseUrl/products';
  static String get ordersUrl => '$baseUrl/orders';
  static String get devicesUrl => '$baseUrl/devices';
  static String get categoriesUrl => '$baseUrl/categories';
  static String get paymentsUrl => '$baseUrl/payments';
  static String get reviewsUrl => '$baseUrl/reviews';
}
