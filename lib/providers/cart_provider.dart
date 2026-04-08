import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

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

class CartState {
  final List<CartItem> items;
  const CartState({this.items = const []});

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.price * item.quantity);
  double get shipping => items.isEmpty ? 0 : 250.0; // KES shipping fee
  double get total => subtotal + shipping;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(CartItem item) {
    final existingIndex = state.items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      final updated = [...state.items];
      updated[existingIndex] =
          updated[existingIndex].copyWith(quantity: updated[existingIndex].quantity + 1);
      state = CartState(items: updated);
    } else {
      state = CartState(items: [...state.items, item]);
    }
  }

  void removeItem(String id) {
    state = CartState(items: state.items.where((i) => i.id != id).toList());
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final updated = state.items.map((item) {
      return item.id == id ? item.copyWith(quantity: quantity) : item;
    }).toList();
    state = CartState(items: updated);
  }

  void clearCart() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
