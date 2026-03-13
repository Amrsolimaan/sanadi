import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanadi/services/firestore/grocery_service.dart';
import '../model/cart_item_model.dart';
import '../model/grocery_product_model.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final GroceryService _groceryService = GroceryService();
  String? _userId;

  CartCubit() : super(CartInitial());

  /// Set user ID and load cart
  void setUser(String userId) {
    _userId = userId;
    loadCart();
  }

  /// Load cart items
  Future<void> loadCart() async {
    if (_userId == null) {
      emit(const CartLoaded(items: []));
      return;
    }

    emit(CartLoading());

    try {
      final items = await _groceryService.getCartItems(_userId!);
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError(message: e.toString()));
    }
  }

  /// Add item to cart
  Future<void> addToCart(GroceryProductModel product,
      {int quantity = 1}) async {
    if (_userId == null) return;

    final currentState = state;
    if (currentState is CartLoaded) {
      emit(currentState.copyWith(isUpdating: true));
    }

    try {
      final cartItem = CartItemModel.fromProduct(product, quantity: quantity);
      final addedItem = await _groceryService.addToCart(_userId!, cartItem);

      if (addedItem != null) {
        emit(CartItemAdded(item: addedItem));
        await loadCart();
      }
    } catch (e) {
      emit(CartError(message: e.toString()));
      if (currentState is CartLoaded) {
        emit(currentState);
      }
    }
  }

  /// Update item quantity (Optimistic)
  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) return;

    final currentState = state;
    if (currentState is! CartLoaded) return;

    // 1. Optimistic Update: Calculate new items locally
    final originalItems = List<CartItemModel>.from(currentState.items);
    final itemIndex = originalItems.indexWhere((i) => i.id == itemId);

    if (itemIndex == -1) return;

    final originalItem = originalItems[itemIndex];
    List<CartItemModel> optimisticItems = List.from(originalItems);

    if (quantity <= 0) {
      optimisticItems.removeAt(itemIndex);
    } else {
      optimisticItems[itemIndex] = originalItem.copyWith(quantity: quantity);
    }

    // 2. Emit Optimistic State
    emit(currentState.copyWith(
      items: optimisticItems,
      isUpdating: false, // Don't show global loader
      updatingItemId: null, // Don't show item loader
    ));

    try {
      // 3. Call Backend
      if (quantity <= 0) {
        await _groceryService.removeFromCart(_userId!, itemId);
        emit(CartItemRemoved(itemId: itemId));
      } else {
        await _groceryService.updateCartItemQuantity(
            _userId!, itemId, quantity);
      }
      
      // Optionally reload to sync fully, or just trust optimistic if simple
      // await loadCart(); 
      // Better to sync to ensure totals/prices are server-verified:
      final syncedItems = await _groceryService.getCartItems(_userId!);
      emit(CartLoaded(items: syncedItems));

    } catch (e) {
      // 4. Revert on Error
      emit(CartError(message: e.toString()));
      // Restore original state
      emit(currentState);
    }
  }

  /// Increase item quantity
  Future<void> increaseQuantity(String itemId) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final item = currentState.items.firstWhere(
        (i) => i.id == itemId,
        orElse: () => throw Exception('Item not found'),
      );
      await updateQuantity(itemId, item.quantity + 1);
    }
  }

  /// Decrease item quantity
  Future<void> decreaseQuantity(String itemId) async {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final item = currentState.items.firstWhere(
        (i) => i.id == itemId,
        orElse: () => throw Exception('Item not found'),
      );
      await updateQuantity(itemId, item.quantity - 1);
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    if (_userId == null) return;

    final currentState = state;
    if (currentState is! CartLoaded) return;

    emit(currentState.copyWith(isUpdating: true, updatingItemId: itemId));

    try {
      await _groceryService.removeFromCart(_userId!, itemId);
      emit(CartItemRemoved(itemId: itemId));
      await loadCart();
    } catch (e) {
      emit(CartError(message: e.toString()));
      emit(currentState);
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    if (_userId == null) return;

    final currentState = state;
    if (currentState is! CartLoaded) return;

    emit(currentState.copyWith(isUpdating: true));

    try {
      await _groceryService.clearCart(_userId!);
      emit(CartCleared());
      emit(const CartLoaded(items: []));
    } catch (e) {
      emit(CartError(message: e.toString()));
      emit(currentState);
    }
  }

  /// Get cart items count
  int get itemsCount {
    if (state is CartLoaded) {
      return (state as CartLoaded).totalItems;
    }
    return 0;
  }

  /// Get subtotal
  double get subtotal {
    if (state is CartLoaded) {
      return (state as CartLoaded).subtotal;
    }
    return 0;
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    if (state is CartLoaded) {
      return (state as CartLoaded)
          .items
          .any((item) => item.productId == productId);
    }
    return false;
  }

  /// Get cart item by product ID
  CartItemModel? getCartItem(String productId) {
    if (state is CartLoaded) {
      final items = (state as CartLoaded).items;
      try {
        return items.firstWhere((item) => item.productId == productId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
