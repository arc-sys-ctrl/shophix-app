import 'product.dart';

class CartItem {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String? selectedSize;
  int quantity;

  CartItem({
    required this.id,
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
      name: p.name,
      brand: p.brand,
      price: p.price,
      originalPrice: p.originalPrice,
      imageUrl: p.imageUrl,
      selectedSize: size,
    );
  }
}
