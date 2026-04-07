import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchProducts();
});

final trendingProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchProducts(isTrending: true);
});

final newArrivalsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchProducts(isNew: true);
});
