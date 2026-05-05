import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/catalog_filter_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
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

  List<Widget> _homeShopRailSlivers(AsyncValue<HomeRails> railsAsync) {
    return railsAsync.when(
      data: (rails) {
        final list = <Widget>[
          SliverToBoxAdapter(
            child: _buildProductSection(
              context,
              title: rails.primaryTitle,
              asyncValue: AsyncValue<List<Product>>.data(rails.primary),
              onRetry: () => ref.invalidate(homeRailsProvider),
            ),
          ),
        ];
        if (rails.showSecondary && rails.secondary.isNotEmpty) {
          list.add(
            SliverToBoxAdapter(
              child: _buildProductSection(
                context,
                title: rails.secondaryTitle,
                asyncValue: AsyncValue<List<Product>>.data(rails.secondary),
                onRetry: () => ref.invalidate(homeRailsProvider),
              ),
            ),
          );
        }
        return list;
      },
      loading: () => [
        SliverToBoxAdapter(
          child: _buildProductSection(
            context,
            title: 'Trending Now',
            asyncValue: const AsyncValue<List<Product>>.loading(),
            onRetry: () => ref.invalidate(homeRailsProvider),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildProductSection(
            context,
            title: 'New Arrivals',
            asyncValue: const AsyncValue<List<Product>>.loading(),
            onRetry: () => ref.invalidate(homeRailsProvider),
          ),
        ),
      ],
      error: (e, st) => [
        SliverToBoxAdapter(
          child: _buildProductSection(
            context,
            title: 'Shop',
            asyncValue: AsyncValue<List<Product>>.error(e, st),
            onRetry: () => ref.invalidate(homeRailsProvider),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final railsAsync = ref.watch(homeRailsProvider);

    return Scaffold(
      backgroundColor: SophixColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homeRailsProvider);
          ref.invalidate(trendingProductsProvider);
          ref.invalidate(newArrivalsProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(categoriesProvider);
          await Future.delayed(const Duration(milliseconds: 600));
        },
        color: SophixColors.accent,
        backgroundColor: SophixColors.surface,
        displacement: 48,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(child: _buildHeroSection(context)),
            SliverToBoxAdapter(child: _buildCategorySection(context)),
            ..._homeShopRailSlivers(railsAsync),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final authState = ref.watch(authProvider);

    final cartItemsCount = ref.watch(cartProvider).totalItems;

    return SliverAppBar(
      backgroundColor: SophixColors.background,
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
          onPressed: () => _showSearch(context),
        ),
        if (authState.user != null)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => _showLogoutDialog(context),
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
              onPressed: () => _showCart(context),
            ),
            if (cartItemsCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: SophixColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cartItemsCount > 99 ? '99+' : '$cartItemsCount',
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
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
          margin: const EdgeInsets.all(20),
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF00D1FF), Color(0xFF003366)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D1FF).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Abstract Mesh Gradient Effect
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'NEW ARRIVALS 2026',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Future of\nSophistication.',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(currentTabProvider.notifier).setTab(1); // Discover Tab
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'EXPLORE',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategoryName(String name) {
    final n = name.toLowerCase();
    if (n.contains('sneaker') || n.contains('shoe') || n.contains('foot')) {
      return Icons.directions_run_rounded;
    }
    if (n.contains('hoodie') || n.contains('shirt') || n.contains('tee') || n.contains('apparel')) {
      return Icons.checkroom_rounded;
    }
    if (n.contains('pant') || n.contains('cargo') || n.contains('jean')) {
      return Icons.accessibility_new_rounded;
    }
    if (n.contains('accessor') || n.contains('watch') || n.contains('hat') || n.contains('bag')) {
      return Icons.watch_rounded;
    }
    if (n.contains('tech')) {
      return Icons.layers_rounded;
    }
    return Icons.category_rounded;
  }

  Widget _buildCategorySection(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (cats) {
        if (cats.isEmpty) {
          return const SizedBox.shrink();
        }
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
              height: 115,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cats.length,
                itemBuilder: (context, index) {
                  final c = cats[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildCategoryCard(
                      context,
                      c.name,
                      _iconForCategoryName(c.name),
                      index == 0,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => Column(
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
            height: 115,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String name, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(browseCategoryFilterProvider.notifier).state = name;
        ref.read(currentTabProvider.notifier).setTab(1);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D1FF).withValues(alpha: 0.1) : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D1FF) : Colors.white.withValues(alpha: 0.05),
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

  Widget _buildProductSection(
    BuildContext context, {
    required String title,
    required AsyncValue<List<Product>> asyncValue,
    required VoidCallback onRetry,
  }) {
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
                  ref.read(currentTabProvider.notifier).setTab(1);
                },
                child: Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SophixColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: asyncValue.when(
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Text(
                    'No products yet',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                  ),
                );
              }
              return ListView.builder(
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
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildProductCardSkeleton(),
              ),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, color: Colors.white.withValues(alpha: 0.35), size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Couldn\'t load products',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(
                        backgroundColor: SophixColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCardSkeleton() {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: SophixColors.surface,
        borderRadius: BorderRadius.circular(SophixRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: SophixColors.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(SophixRadii.md)),
              ),
              child: Center(
                child: Icon(Icons.image_outlined, color: Colors.white.withValues(alpha: 0.06), size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10, width: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Container(height: 14, width: 120, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Container(height: 12, width: 72, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: SophixColors.surface,
          borderRadius: BorderRadius.circular(SophixRadii.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(SophixRadii.md)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SophixProductImage(
                      imageUrl: product.imageUrl,
                      borderRadius: BorderRadius.zero,
                      memCacheWidth: 400,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => HapticFeedback.selectionClick(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.favorite_border, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                    if (product.isNew)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: SophixColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
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
                      color: SophixColors.accent,
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
    ref.read(currentTabProvider.notifier).setTab(1);
  }

  void _showCart(BuildContext context) {
    ref.read(currentTabProvider.notifier).setTab(2);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SophixColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SophixRadii.md)),
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
