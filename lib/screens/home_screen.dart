import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart';
import 'auth_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroAnimationController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut),
    );
    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut));
    _heroAnimationController.forward();
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsyncValue = ref.watch(trendingProductsProvider);
    final newArrivalsAsyncValue = ref.watch(newArrivalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh products
          ref.invalidate(trendingProductsProvider);
          ref.invalidate(newArrivalsProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        color: const Color(0xFF00D1FF),
        backgroundColor: const Color(0xFF161B22),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, ref),
            SliverToBoxAdapter(child: _buildHeroSection(context)),
            SliverToBoxAdapter(child: _buildCategorySection(context)),
            SliverToBoxAdapter(
              child: _buildProductSection(
                context,
                title: "Trending Now",
                asyncValue: trendingAsyncValue,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildProductSection(
                context,
                title: "New Arrivals",
                asyncValue: newArrivalsAsyncValue,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final cartItemsCount = ref.watch(cartProvider).totalItems;

    return SliverAppBar(
      backgroundColor: const Color(0xFF0A0E14),
      floating: true,
      centerTitle: true,
      title: Text(
        'Sophix',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white70),
          onPressed: () => _showSearch(context, ref),
        ),
        if (authState.user != null)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => _showLogoutDialog(context, ref),
          )
        else
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            ),
          ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              onPressed: () => _showCart(context, ref),
            ),
            if (cartItemsCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D1FF),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    cartItemsCount.toString(),
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return FadeTransition(
      opacity: _heroFadeAnimation,
      child: SlideTransition(
        position: _heroSlideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D1FF).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFF00D1FF).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NEW SEASON',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00D1FF),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Sophisticated\nInnovation.',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Experience the future of tech-wear and accessories.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to shop
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D1FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'SHOP NOW',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    final categories = [
      {'name': 'Sneakers', 'icon': Icons.directions_run},
      {'name': 'Hoodies', 'icon': Icons.checkroom},
      {'name': 'Pants', 'icon': Icons.accessibility},
      {'name': 'Accessories', 'icon': Icons.watch},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Text(
            'Shop by Category',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildCategoryCard(context, category['name'] as String, category['icon'] as IconData, index == 0),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String name, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // TODO: Filter by category
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D1FF).withOpacity(0.1) : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D1FF) : Colors.white.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00D1FF) : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isSelected ? const Color(0xFF00D1FF) : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection(BuildContext context, {required String title, required AsyncValue asyncValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full list
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: asyncValue.when(
            data: (products) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildProductCard(context, product),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00D1FF))),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load products',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(asyncValue is AsyncData ? trendingProductsProvider : newArrivalsProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D1FF),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Color(0xFF1E2832),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white10,
                        size: 60,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    if (product.isNew)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D1FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: const Color(0xFF00D1FF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} KES',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${product.originalPrice!.toStringAsFixed(2)} KES',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white38,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating} (${product.reviewsCount})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    // TODO: Implement search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search feature coming soon')),
    );
  }

  void _showCart(BuildContext context) {
    // TODO: Implement cart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cart feature coming soon')),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged out successfully', style: GoogleFonts.inter()),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Logout',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
