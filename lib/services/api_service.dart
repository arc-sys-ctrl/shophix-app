import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';

import '../config/env_config.dart';

const Duration _requestTimeout = Duration(seconds: 20);

/// Public storefront APIs may return a raw JSON array or a paginated envelope.
List<dynamic> decodeJsonListBody(String body) {
  final decoded = json.decode(body);
  if (decoded is List<dynamic>) return decoded;
  if (decoded is Map<String, dynamic>) {
    for (final key in ['data', 'products', 'items', 'results']) {
      final v = decoded[key];
      if (v is List<dynamic>) return v;
    }
  }
  throw FormatException(
    'Expected a JSON array or an object with data/products/items/results list.',
  );
}

String _apiErrorMessage(http.Response response) {
  final body = response.body;
  try {
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) {
      return (decoded['message'] ?? decoded['error'] ?? decoded['detail'] ?? body).toString();
    }
  } catch (_) {}
  return '${response.statusCode}: $body';
}

class ApiService {
  static final String baseUrl = EnvConfig.baseUrl; 

  Future<List<Product>> fetchProducts({
    bool? isNew,
    bool? isTrending,
    String? category,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (isNew != null) queryParams['is_new'] = isNew.toString();
    if (isTrending != null) queryParams['is_trending'] = isTrending.toString();
    if (category != null && category.trim().isNotEmpty) {
      queryParams['category'] = category.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri).timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final data = decodeJsonListBody(response.body);
        return data
            .map((row) => Product.fromJson(row as Map<String, dynamic>))
            .where((p) => p.isStorefrontVisible)
            .toList();
      } else {
        throw Exception(_apiErrorMessage(response));
      }
    } on TimeoutException {
      throw Exception('Request timed out while loading products.');
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse(EnvConfig.categoriesUrl);
    try {
      final response = await http.get(uri).timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final list = decodeJsonListBody(response.body);
        return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception(_apiErrorMessage(response));
    } on TimeoutException {
      throw Exception('Request timed out while loading categories.');
    } catch (e) {
      throw Exception('Error loading categories: $e');
    }
  }

  String getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    // Remove /api and get origin for static files
    final origin = baseUrl.replaceAll('/api', '');
    return '$origin$path';
  }

  // --- Payment APIs ---

  Future<Map<String, dynamic>> createCustomerOrder({
    required String token,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String shippingAddress,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String paymentMethod = 'mpesa',
    String channel = 'app',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'items': items,
        'totalAmount': totalAmount,
        'shippingAddress': shippingAddress,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'paymentMethod': paymentMethod,
        'channel': channel,
      }),
    ).timeout(_requestTimeout);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_apiErrorMessage(response));
  }

  Future<List<dynamic>> fetchUserOrders(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/user'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(_requestTimeout);
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    }
    throw Exception(_apiErrorMessage(response));
  }

  Future<Map<String, dynamic>> initiateMpesaStkPush(
    String phoneNumber,
    double amount, {
    String? orderId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/mpesa/stk-push'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'amount': amount,
        if (orderId != null) 'accountReference': orderId,
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_apiErrorMessage(response));
  }

  Future<String> createStripePaymentIntent(double amount, String currency) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/stripe/create-intent'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': amount,
        'currency': currency,
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['clientSecret'];
    } else {
      throw Exception(_apiErrorMessage(response));
    }
  }
}
