import 'package:flutter/foundation.dart';

/// Environment-aware configuration for the Sophix mobile app.
class EnvConfig {
  /// Toggle this to change between local development and production.
  static const bool isProduction = kReleaseMode;

  /// The base URL for the Sophix backend API.
  /// Update the production URL once you have a live domain or static IP.
  static String get baseUrl {
    if (isProduction) {
      // TODO: Replace with your actual production domain (e.g., https://api.sophix-luxury.com)
      return 'https://api.sophix-luxury.com/api';
    } else {
      // Default to localhost for emulator/simulator development.
      // Use 10.0.2.2 for Android Emulator if hitting a local server.
      return 'http://localhost:5001/api';
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
