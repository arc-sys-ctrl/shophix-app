import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

import '../config/env_config.dart';

class ApiService {
  static final String baseUrl = EnvConfig.baseUrl; 

  Future<List<Product>> fetchProducts({bool? isNew, bool? isTrending}) async {
    final queryParams = <String, String>{};
    if (isNew != null) queryParams['is_new'] = isNew.toString();
    if (isTrending != null) queryParams['is_trending'] = isTrending.toString();

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  String getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    // Remove /api and get origin for static files
    final origin = baseUrl.replaceAll('/api', '');
    return '$origin$path';
  }

  // --- Payment APIs ---

  Future<Map<String, dynamic>> initiateMpesaStkPush(String phoneNumber, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/mpesa/stk-push'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'amount': amount,
        'accountReference': 'SophixOrder',
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('M-Pesa Payment Failed: ${response.body}');
    }
  }

  Future<String> createStripePaymentIntent(double amount, String currency) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/stripe/create-intent'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': amount,
        'currency': currency,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['clientSecret'];
    } else {
      throw Exception('Stripe Payment Initiation Failed: ${response.body}');
    }
  }
}
