import 'package:flutter/foundation.dart';

/// Environment-aware configuration for the Sophix mobile app.
class EnvConfig {
  /// Toggle this to change between local development and production.
  static const bool isProduction = kReleaseMode;

  /// The base URL for the Sophix backend API.
  /// Update the production URL once you have a live domain or static IP.
  static String get baseUrl {
    if (isProduction) {
      // TODO: Replace with your actual production domain
      return 'https://api.sophix-luxury.com/api';
    } else {
      // For local development
      // Use 10.0.2.2 for Android Emulator, otherwise localhost
      const String host = kIsWeb ? 'localhost' : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');
      return 'http://$host:5000/api';
    }
  }

  static String get authUrl => '$baseUrl/auth';
  static String get productsUrl => '$baseUrl/products';
  static String get ordersUrl => '$baseUrl/orders';
  static String get devicesUrl => '$baseUrl/devices';
  static String get categoriesUrl => '$baseUrl/categories';
  static String get paymentsUrl => '$baseUrl/payments';
  static String get reviewsUrl => '$baseUrl/reviews';
}
