import 'package:equatable/equatable.dart';
import '../model/grocery_order_model.dart';
import '../model/grocery_category_model.dart';
import '../model/cart_item_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderLoading extends OrderState {}

class OrderCreating extends OrderState {}

class OrderCreated extends OrderState {
  final GroceryOrderModel order;

  const OrderCreated({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrderState {
  final String message;

  const OrderError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============================================
// Order History State
// ============================================

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();

  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<GroceryOrderModel> orders;
  final List<OrderItemModel> purchasedItems;
  final List<OrderItemModel> filteredItems;
  final List<GroceryCategoryModel> categories;
  final String? selectedCategoryId;
  final Set<String> selectedItemIds;
  final bool isSelectionMode;
  final bool isDeleting;

  const OrderHistoryLoaded({
    required this.orders,
    required this.purchasedItems,
    required this.filteredItems,
    this.categories = const [],
    this.selectedCategoryId,
    this.selectedItemIds = const {},
    this.isSelectionMode = false,
    this.isDeleting = false,
  });

  @override
  List<Object?> get props => [
        orders,
        purchasedItems,
        filteredItems,
        categories,
        selectedCategoryId,
        selectedItemIds,
        isSelectionMode,
        isDeleting,
      ];

  OrderHistoryLoaded copyWith({
    List<GroceryOrderModel>? orders,
    List<OrderItemModel>? purchasedItems,
    List<OrderItemModel>? filteredItems,
    List<GroceryCategoryModel>? categories,
    String? selectedCategoryId,
    Set<String>? selectedItemIds,
    bool? isSelectionMode,
    bool? isDeleting,
    bool clearCategoryFilter = false,
  }) {
    return OrderHistoryLoaded(
      orders: orders ?? this.orders,
      purchasedItems: purchasedItems ?? this.purchasedItems,
      filteredItems: filteredItems ?? this.filteredItems,
      categories: categories ?? this.categories,
      selectedCategoryId:
          clearCategoryFilter ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============================================
// Reorder State
// ============================================

abstract class ReorderState extends Equatable {
  const ReorderState();

  @override
  List<Object?> get props => [];
}

class ReorderInitial extends ReorderState {}

class ReorderLoading extends ReorderState {}

class ReorderHistoryLoaded extends ReorderState {
  final List<GroceryOrderModel> orders;

  const ReorderHistoryLoaded({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class ReorderReady extends ReorderState {
  final List<CartItemModel> items;
  final double totalPrice;

  const ReorderReady({
    required this.items,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [items, totalPrice];

  ReorderReady copyWith({
    List<CartItemModel>? items,
    double? totalPrice,
  }) {
    return ReorderReady(
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class ReorderSuccess extends ReorderState {
  final GroceryOrderModel order;

  const ReorderSuccess({required this.order});

  @override
  List<Object?> get props => [order];
}

class ReorderError extends ReorderState {
  final String message;

  const ReorderError({required this.message});

  @override
  List<Object?> get props => [message];
}
