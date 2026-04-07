import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator to hit localhost, or actual IP for physical devices
  static const String baseUrl = 'http://localhost:5001/api'; 

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
    return 'http://localhost:5001$path';
  }
}
