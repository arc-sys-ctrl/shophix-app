import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'product_provider.dart';

/// Categories from CRM / `GET /categories` (same DB as storefront).
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.fetchCategories();
});
