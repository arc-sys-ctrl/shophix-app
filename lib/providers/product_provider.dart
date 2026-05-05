import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

/// One [fetchProducts] call, then layout for Home: CRM flags drive rails; if none are set,
/// the full active catalog is shown so products still appear after CRM sync.
class HomeRails {
  final String primaryTitle;
  final List<Product> primary;
  final String secondaryTitle;
  final List<Product> secondary;
  final bool showSecondary;

  const HomeRails({
    required this.primaryTitle,
    required this.primary,
    required this.secondaryTitle,
    required this.secondary,
    required this.showSecondary,
  });

  factory HomeRails.fromCatalog(List<Product> all) {
    if (all.isEmpty) {
      return const HomeRails(
        primaryTitle: 'Trending Now',
        primary: [],
        secondaryTitle: 'New Arrivals',
        secondary: [],
        showSecondary: false,
      );
    }
    final taggedTrending = all.where((p) => p.isTrending).toList();
    final taggedNew = all.where((p) => p.isNew).toList();

    if (taggedTrending.isNotEmpty && taggedNew.isNotEmpty) {
      return HomeRails(
        primaryTitle: 'Trending Now',
        primary: taggedTrending,
        secondaryTitle: 'New Arrivals',
        secondary: taggedNew,
        showSecondary: true,
      );
    }
    if (taggedTrending.isNotEmpty && taggedNew.isEmpty) {
      return HomeRails(
        primaryTitle: 'Trending Now',
        primary: taggedTrending,
        secondaryTitle: 'New Arrivals',
        secondary: const [],
        showSecondary: false,
      );
    }
    if (taggedTrending.isEmpty && taggedNew.isNotEmpty) {
      final exclude = taggedNew.map((e) => e.id).toSet();
      final more = _productsExcludingIds(all, exclude, 40);
      return HomeRails(
        primaryTitle: 'New Arrivals',
        primary: taggedNew,
        secondaryTitle: 'More from the catalog',
        secondary: more,
        showSecondary: more.isNotEmpty,
      );
    }
    return HomeRails(
      primaryTitle: 'Shop the catalog',
      primary: all.take(48).toList(),
      secondaryTitle: '',
      secondary: const [],
      showSecondary: false,
    );
  }
}

List<Product> _productsExcludingIds(List<Product> pool, Set<String> ids, int max) {
  final out = <Product>[];
  for (final p in pool) {
    if (ids.contains(p.id)) continue;
    out.add(p);
    if (out.length >= max) break;
  }
  return out;
}

final homeRailsProvider = FutureProvider.autoDispose<HomeRails>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final all = await api.fetchProducts();
  return HomeRails.fromCatalog(all);
});

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

/// Active products filtered by `category_name` on the server (CRM sync).
final productsInCategoryProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, category) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.fetchProducts(category: category);
});
