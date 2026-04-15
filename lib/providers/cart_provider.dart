import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

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
