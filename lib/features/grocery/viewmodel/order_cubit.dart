import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanadi/services/firestore/grocery_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/cart_item_model.dart';
import '../model/grocery_order_model.dart';
import '../model/grocery_category_model.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final GroceryService _groceryService = GroceryService();

  // WhatsApp number for orders
  static const String whatsappNumber = '201008864664';

  OrderCubit() : super(OrderInitial());

  /// Create order and send to WhatsApp
  Future<void> createOrder({
    required String uid, // ✅ تغيير من userId إلى uid
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required List<CartItemModel> items,
    String? notes,
    required String lang,
  }) async {
    emit(OrderCreating());

    try {
      // Create order in Firebase
      final order = await _groceryService.createOrder(
        uid: uid, // ✅ تغيير من userId إلى uid
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        items: items,
        notes: notes,
      );

      if (order == null) {
        emit(const OrderError(message: 'Failed to create order'));
        return;
      }

      // Send WhatsApp message
      await _sendWhatsAppMessage(order, lang);

      // Mark WhatsApp as sent
      await _groceryService.markWhatsAppSent(order.id);

      emit(OrderCreated(order: order));
    } catch (e) {
      emit(OrderError(message: e.toString()));
    }
  }

  /// Send WhatsApp message
  Future<void> _sendWhatsAppMessage(
      GroceryOrderModel order, String lang) async {
    try {
      final message = order.generateWhatsAppMessage(lang);
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';

      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // WhatsApp sending failed, but order is created
      print('WhatsApp error: $e');
    }
  }

  /// Reset state
  void reset() {
    emit(OrderInitial());
  }
}

// ============================================
// Order History Cubit
// ============================================

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final GroceryService _groceryService = GroceryService();
  String? _uid; // ✅ تغيير من _userId إلى _uid

  OrderHistoryCubit() : super(OrderHistoryInitial());

  /// Set user and load history
  void setUser(String uid) {
    // ✅ تغيير من userId إلى uid
    _uid = uid;
    loadOrderHistory();
  }

  /// Load order history
  Future<void> loadOrderHistory() async {
    if (_uid == null) return;

    emit(OrderHistoryLoading());

    try {
      final orders = await _groceryService.getUserOrders(_uid!); // ✅ تغيير
      final categories = await _groceryService.getCategories();

      // Flatten all items from orders
      final purchasedItems = <OrderItemModel>[];
      for (var order in orders) {
        if (order.status != OrderStatus.cancelled) {
          purchasedItems.addAll(order.items);
        }
      }

      emit(OrderHistoryLoaded(
        orders: orders,
        purchasedItems: purchasedItems,
        filteredItems: purchasedItems,
        categories: categories,
      ));
    } catch (e) {
      emit(OrderHistoryError(message: e.toString()));
    }
  }

  /// Filter by category
  Future<void> filterByCategory(String? categoryId) async {
    if (state is! OrderHistoryLoaded || _uid == null) return;

    final currentState = state as OrderHistoryLoaded;

    if (categoryId == null || categoryId.isEmpty) {
      // Show all items
      emit(currentState.copyWith(
        filteredItems: currentState.purchasedItems,
        clearCategoryFilter: true,
      ));
      return;
    }

    // Filter items by category
    final filteredItems = <OrderItemModel>[];
    for (var item in currentState.purchasedItems) {
      final product = await _groceryService.getProductById(item.productId);
      if (product != null && product.categoryId == categoryId) {
        filteredItems.add(item);
      }
    }

    emit(currentState.copyWith(
      filteredItems: filteredItems,
      selectedCategoryId: categoryId,
    ));
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    if (state is! OrderHistoryLoaded) return;

    final currentState = state as OrderHistoryLoaded;
    emit(currentState.copyWith(
      isSelectionMode: !currentState.isSelectionMode,
      selectedItemIds: {},
    ));
  }

  /// Toggle item selection
  void toggleItemSelection(String productId) {
    if (state is! OrderHistoryLoaded) return;

    final currentState = state as OrderHistoryLoaded;
    final selectedIds = Set<String>.from(currentState.selectedItemIds);

    if (selectedIds.contains(productId)) {
      selectedIds.remove(productId);
    } else {
      selectedIds.add(productId);
    }

    emit(currentState.copyWith(selectedItemIds: selectedIds));
  }

  /// Select all items
  void selectAll() {
    if (state is! OrderHistoryLoaded) return;

    final currentState = state as OrderHistoryLoaded;
    final allIds = currentState.filteredItems.map((i) => i.productId).toSet();

    emit(currentState.copyWith(selectedItemIds: allIds));
  }

  /// Deselect all items
  void deselectAll() {
    if (state is! OrderHistoryLoaded) return;

    final currentState = state as OrderHistoryLoaded;
    emit(currentState.copyWith(selectedItemIds: {}));
  }

  /// Delete selected items (remove from display only)
  void deleteSelectedItems() {
    if (state is! OrderHistoryLoaded) return;

    final currentState = state as OrderHistoryLoaded;
    final selectedIds = currentState.selectedItemIds;

    final remainingItems = currentState.purchasedItems
        .where((item) => !selectedIds.contains(item.productId))
        .toList();

    final remainingFilteredItems = currentState.filteredItems
        .where((item) => !selectedIds.contains(item.productId))
        .toList();

    emit(currentState.copyWith(
      purchasedItems: remainingItems,
      filteredItems: remainingFilteredItems,
      selectedItemIds: {},
      isSelectionMode: false,
    ));
  }

  /// Refresh history
  Future<void> refresh() async {
    await loadOrderHistory();
  }
}

// ============================================
// Reorder Cubit
// ============================================

class ReorderCubit extends Cubit<ReorderState> {
  final GroceryService _groceryService = GroceryService();

  static const String whatsappNumber = '201008864664';

  ReorderCubit() : super(ReorderInitial());

  /// Initialize reorder with multiple items
  void initReorder(List<OrderItemModel> items) {
    // Convert OrderItemModel to CartItemModel for editable quantity
    final cartItems = items.map((item) {
      return CartItemModel(
        id: '', // Will be generated or ignored
        productId: item.productId,
        quantity: item.quantity, // Default to previous quantity
        price: item.price,
        addedAt: DateTime.now(),
        nameAr: item.nameAr,
        nameEn: item.nameEn,
        imageUrl: item.imageUrl,
        unit: item.unit,
      );
    }).toList();

    emit(ReorderReady(
      items: cartItems,
      totalPrice: _calculateTotal(cartItems),
    ));
  }

  /// Load user orders history
  Future<void> loadUserOrders(String uid) async {
    emit(ReorderLoading());
    try {
      final orders = await _groceryService.getUserOrders(uid, limit: 20);
      
      if (orders.isNotEmpty) {
        emit(ReorderHistoryLoaded(orders: orders));
      } else {
        emit(const ReorderError(message: 'No previous orders found'));
      }
    } catch (e) {
      emit(ReorderError(message: e.toString()));
    }
  }

  /// Update quantity for a specific item
  void updateQuantity(String productId, int newQuantity) {
    if (state is! ReorderReady) return;

    final currentState = state as ReorderReady;
    
    // Create new list with updated item
    final updatedItems = currentState.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    emit(currentState.copyWith(
      items: updatedItems,
      totalPrice: _calculateTotal(updatedItems),
    ));
  }

  /// Remove item from reorder list
  void removeItem(String productId) {
    if (state is! ReorderReady) return;

    final currentState = state as ReorderReady;
    
    final updatedItems = currentState.items
        .where((item) => item.productId != productId)
        .toList();

    if (updatedItems.isEmpty) {
      // Optional: Handle empty state if needed, or just keep it empty
    }

    emit(currentState.copyWith(
      items: updatedItems,
      totalPrice: _calculateTotal(updatedItems),
    ));
  }

  /// Calculate total price
  double _calculateTotal(List<CartItemModel> items) {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  /// Place reorder
  Future<void> placeReorder({
    required String uid,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    String? notes,
    required String lang,
  }) async {
    if (state is! ReorderReady) return;

    final currentState = state as ReorderReady;
    
    if (currentState.items.isEmpty) {
       emit(const ReorderError(message: 'No items to reorder'));
       return;
    }

    emit(ReorderLoading());

    try {
      // Create order
      final order = await _groceryService.createOrder(
        uid: uid,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        items: currentState.items,
        notes: notes,
      );

      if (order == null) {
        emit(const ReorderError(message: 'Failed to create order'));
        return;
      }

      // Send WhatsApp
      await _sendWhatsAppMessage(order, lang);
      await _groceryService.markWhatsAppSent(order.id);

      emit(ReorderSuccess(order: order));
    } catch (e) {
      emit(ReorderError(message: e.toString()));
    }
  }

  /// Send WhatsApp message
  Future<void> _sendWhatsAppMessage(
      GroceryOrderModel order, String lang) async {
    try {
      final message = order.generateWhatsAppMessage(lang);
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';

      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('WhatsApp error: $e');
    }
  }

  /// Reset state
  void reset() {
    emit(ReorderInitial());
  }
}
