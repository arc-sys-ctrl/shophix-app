import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> with TickerProviderStateMixin {
  String? selectedSize;
  int quantity = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );
    _animationController.forward();
    
    if (widget.product.sizes.isNotEmpty) {
      selectedSize = widget.product.sizes.first;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (selectedSize == null && widget.product.sizes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a size', style: GoogleFonts.inter()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cartItem = CartItem.fromProduct(widget.product, size: selectedSize);
    cartItem.quantity = quantity;
    
    ref.read(cartProvider.notifier).addItem(cartItem);
    
    HapticFeedback.heavyImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${widget.product.name} to cart', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00D1FF),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.black,
          onPressed: () {
            // This would navigate to cart tab if integrated with navigation provider
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SophixColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),
                      if (widget.product.sizes.isNotEmpty) ...[
                        _buildSizeSelector(),
                        const SizedBox(height: 32),
                      ],
                      _buildQuantitySelector(),
                      const SizedBox(height: 32),
                      _buildDescription(),
                      const SizedBox(height: 40),
                      _buildSpecs(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.45,
      elevation: 0,
      pinned: true,
      stretch: true,
      backgroundColor: SophixColors.background,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          children: [
            Hero(
              tag: 'product_${widget.product.id}',
              child: PageView.builder(
                controller: _pageController,
                itemCount: 1 + (widget.product.imageUrls.length),
                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                itemBuilder: (context, index) {
                  final images = [widget.product.imageUrl, ...widget.product.imageUrls];
                  final imageUrl = images[index];
                  return SizedBox.expand(
                    child: SophixProductImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 900,
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    SophixColors.background,
                    Colors.transparent,
                    Colors.transparent,
                    SophixColors.background.withValues(alpha: 0.5),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            if (widget.product.imageUrls.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    1 + widget.product.imageUrls.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentImageIndex == index ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index ? SophixColors.accent : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.brand.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00D1FF),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.name,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00D1FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00D1FF).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFF00D1FF), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.product.rating.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${widget.product.price.toStringAsFixed(2)} KES',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (widget.product.originalPrice != null) ...[
              const SizedBox(width: 12),
              Text(
                '${widget.product.originalPrice!.toStringAsFixed(2)} KES',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white38,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECT SIZE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white54,
                letterSpacing: 1,
              ),
            ),
            Text(
              'SIZE GUIDE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00D1FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.product.sizes.length,
            itemBuilder: (context, index) {
              final size = widget.product.sizes[index];
              final isSelected = selectedSize == size;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => selectedSize = size);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00D1FF) : const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00D1FF) : Colors.white.withValues(alpha: 0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        size,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUANTITY',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 56,
          width: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove, size: 20),
                color: quantity > 1 ? Colors.white : Colors.white24,
              ),
              Text(
                quantity.toString(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add, size: 20),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final hasDescription = widget.product.description.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THE STORY',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hasDescription
              ? widget.product.description
              : 'No product details yet. Update this product description in CRM to show richer details here.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white.withValues(alpha: hasDescription ? 0.7 : 0.45),
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildSpecRow(Icons.verified_user_outlined, 'Vendor', widget.product.vendor),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildSpecRow(Icons.category_outlined, 'Category', widget.product.categoryName),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildSpecRow(Icons.local_shipping_outlined, 'Shipping', 'Express Delivery'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D1FF), size: 20),
        const SizedBox(width: 16),
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0E14).withValues(alpha: 0.0),
            const Color(0xFF0A0E14),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Hero(
              tag: 'action_${widget.product.id}',
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D1FF),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'ADD TO CART',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}