import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import '../models/cart_item.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: SophixColors.background,
      appBar: AppBar(
        backgroundColor: SophixColors.background,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () => _clearCartDialog(context, ref),
              child: Text(
                'Clear All',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: cartState.isEmpty ? _buildEmptyCart(context, ref) : _buildCartContent(context, ref, cartState),
    );
  }

  Widget _buildEmptyCart(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => ref.read(currentTabProvider.notifier).setTab(0),
            style: FilledButton.styleFrom(
              backgroundColor: SophixColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SophixRadii.sm),
              ),
            ),
            child: Text(
              'Browse products',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, WidgetRef ref, CartState cartState) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartState.items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCartItem(context, ref, cartState.items[index]),
              );
            },
          ),
        ),
        _buildOrderSummary(context, ref, cartState),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        ref.read(cartProvider.notifier).removeItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from cart', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SophixColors.surface,
          borderRadius: BorderRadius.circular(SophixRadii.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SophixRadii.sm),
              child: SizedBox(
                width: 80,
                height: 80,
                child: SophixProductImage(
                  imageUrl: item.imageUrl,
                  memCacheWidth: 200,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.brand.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: const Color(0xFF00D1FF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.selectedSize != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${item.selectedSize}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${item.price.toStringAsFixed(2)} KES',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                    ),
                    Container(
                      width: 40,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          item.quantity.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(item.price * item.quantity).toStringAsFixed(2)} KES',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF00D1FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onPressed != null ? const Color(0xFF00D1FF).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onPressed != null ? const Color(0xFF00D1FF) : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? const Color(0xFF00D1FF) : Colors.white38,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, WidgetRef ref, CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SophixColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SophixRadii.lg)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', cartState.subtotal),
          const SizedBox(height: 12),
          _buildSummaryRow('Shipping', cartState.shipping, isFree: cartState.shipping == 0),
          const SizedBox(height: 12),
          _buildSummaryRow('Tax (16%)', cartState.subtotal * 0.16),
          const Divider(height: 24, color: Colors.white10),
          _buildSummaryRow('Total', cartState.total + (cartState.subtotal * 0.16), isTotal: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: cartState.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            cartItems: cartState.items,
                            orderTotal: cartState.total + (cartState.subtotal * 0.16),
                            onOrderComplete: () => ref.read(cartProvider.notifier).clearCart(),
                          ),
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: SophixColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Proceed to Checkout',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isFree = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white,
          ),
        ),
        Text(
          isFree ? 'FREE' : '${amount.toStringAsFixed(2)} KES',
          style: GoogleFonts.inter(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isFree ? Colors.green : (isTotal ? const Color(0xFF00D1FF) : Colors.white70),
          ),
        ),
      ],
    );
  }

  void _clearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Cart',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
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
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cart cleared', style: GoogleFonts.inter()),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Clear',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}