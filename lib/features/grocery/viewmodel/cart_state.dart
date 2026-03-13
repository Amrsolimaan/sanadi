import 'package:equatable/equatable.dart';
import '../model/cart_item_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItemModel> items;
  final bool isUpdating;
  final String? updatingItemId;

  const CartLoaded({
    required this.items,
    this.isUpdating = false,
    this.updatingItemId,
  });

  /// Total items count
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Total amount (same as subtotal since no delivery fee)
  double get totalAmount => subtotal;

  /// Is cart empty
  bool get isEmpty => items.isEmpty;

  /// Is cart not empty
  bool get isNotEmpty => items.isNotEmpty;

  /// Check minimum order
  bool get meetsMinimumOrder => subtotal >= 50;

  @override
  List<Object?> get props => [items, isUpdating, updatingItemId];

  CartLoaded copyWith({
    List<CartItemModel>? items,
    bool? isUpdating,
    String? updatingItemId,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      isUpdating: isUpdating ?? this.isUpdating,
      updatingItemId: updatingItemId,
    );
  }
}

class CartError extends CartState {
  final String message;

  const CartError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CartItemAdded extends CartState {
  final CartItemModel item;

  const CartItemAdded({required this.item});

  @override
  List<Object?> get props => [item];
}

class CartItemRemoved extends CartState {
  final String itemId;

  const CartItemRemoved({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

class CartCleared extends CartState {}
