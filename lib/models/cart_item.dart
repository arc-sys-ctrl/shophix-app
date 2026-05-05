import 'product.dart';

class CartItem {
  final String id;
  /// Product UUID (for checkout API).
  final String productId;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String? selectedSize;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.brand,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.selectedSize,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      brand: brand,
      price: price,
      originalPrice: originalPrice,
      imageUrl: imageUrl,
      selectedSize: selectedSize,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromProduct(Product p, {String? size}) {
    return CartItem(
      id: '${p.id}_${size ?? 'default'}',
      productId: p.id,
      name: p.name,
      brand: p.brand,
      price: p.price,
      originalPrice: p.originalPrice,
      imageUrl: p.imageUrl,
      selectedSize: size,
    );
  }
}
