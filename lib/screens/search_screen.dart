import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/catalog_filter_provider.dart';
import 'product_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _recentSearches = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.sublist(0, 5);
        }
      });
    }
  }

  IconData _iconForCategoryName(String name) {
    final n = name.toLowerCase();
    if (n.contains('sneaker') || n.contains('shoe')) return Icons.bolt_rounded;
    if (n.contains('hoodie') || n.contains('apparel') || n.contains('shirt')) {
      return Icons.checkroom_rounded;
    }
    if (n.contains('accessor') || n.contains('watch')) return Icons.watch_rounded;
    if (n.contains('tech')) return Icons.layers_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final browseCat = ref.watch(browseCategoryFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(browseCat),
            Expanded(
              child: browseCat != null && _searchQuery.isEmpty
                  ? _buildCategoryBrowse(browseCat)
                  : (_searchQuery.isEmpty
                      ? _buildSearchSuggestions()
                      : _buildSearchResults(productsAsync)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(String? browseCat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (browseCat != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      browseCat,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(browseCategoryFilterProvider.notifier).state = null;
                    },
                    child: Text(
                      'CLEAR',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00D1FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search the future...',
                    hintStyle: GoogleFonts.inter(color: Colors.white24),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00D1FF), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(browseCategoryFilterProvider.notifier).state = null;
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      ref.read(browseCategoryFilterProvider.notifier).state = null;
                    }
                    setState(() => _searchQuery = value);
                  },
                  onSubmitted: _onSearch,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBrowse(String categoryName) {
    final async = ref.watch(productsInCategoryProvider(categoryName));
    return RefreshIndicator(
      color: const Color(0xFF00D1FF),
      backgroundColor: const Color(0xFF161B22),
      onRefresh: () async {
        ref.invalidate(productsInCategoryProvider(categoryName));
        ref.invalidate(productsProvider);
        ref.invalidate(categoriesProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: async.when(
        data: _buildProductListView,
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF))),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(productsInCategoryProvider(categoryName)),
            child: Text(
              'RETRY',
              style: GoogleFonts.inter(color: const Color(0xFF00D1FF), fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT SEARCHES',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white38,
                  letterSpacing: 1.5,
                ),
              ),
              if (_recentSearches.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _recentSearches.clear()),
                  child: Text(
                    'CLEAR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00D1FF).withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recentSearches.map((search) => _buildSearchChip(search)).toList(),
          ),
          const SizedBox(height: 40),
          Text(
            'POPULAR CATEGORIES',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white38,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _searchController.text = text;
        setState(() => _searchQuery = text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 14, color: Colors.white38),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categoriesAsync = ref.watch(categoriesProvider);
    const colors = [
      Color(0xFF00D1FF),
      Color(0xFF7C3AED),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF00BCD4),
    ];

    return categoriesAsync.when(
      data: (cats) {
        if (cats.isEmpty) {
          return Text(
            'Categories from your store will show here once added in the CRM.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13, height: 1.4),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
          ),
          itemCount: cats.length,
          itemBuilder: (context, index) {
            final c = cats[index];
            final color = colors[index % colors.length];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(browseCategoryFilterProvider.notifier).state = c.name;
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iconForCategoryName(c.name),
                      color: color,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF00D1FF)),
        ),
      ),
      error: (_, __) => Text(
        'Could not load categories.',
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
      ),
    );
  }

  Widget _buildProductListView(List<Product> products) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSearchResultCard(product),
        );
      },
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Product>> productsAsync) {
    return productsAsync.when(
      data: (products) {
        final filteredProducts = products.where((product) {
          final query = _searchQuery.toLowerCase();
          return product.name.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query) ||
              product.categoryName.toLowerCase().contains(query);
        }).toList();

        return _buildProductListView(filteredProducts);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF))),
      error: (err, stack) => _buildErrorState(),
    );
  }

  Widget _buildSearchResultCard(Product product) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E14),
                borderRadius: BorderRadius.circular(14),
                image: product.imageUrl.isNotEmpty ? DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: product.imageUrl.isEmpty ? Icon(
                Icons.inventory_2_outlined,
                color: Colors.white.withValues(alpha: 0.05),
                size: 24,
              ) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: const Color(0xFF00D1FF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} KES',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, color: Color(0xFF00D1FF), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.1), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, color: Colors.white12, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'Nothing found',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different keyword or category',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text('Something went wrong', style: GoogleFonts.inter(color: Colors.white70)),
          TextButton(
            onPressed: () {
              ref.invalidate(productsProvider);
              ref.invalidate(categoriesProvider);
            },
            child: Text('RETRY', style: GoogleFonts.inter(color: const Color(0xFF00D1FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}