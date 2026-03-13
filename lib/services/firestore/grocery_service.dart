import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sanadi/features/grocery/model/cart_item_model.dart';
import 'package:sanadi/features/grocery/model/grocery_category_model.dart';
import 'package:sanadi/features/grocery/model/grocery_order_model.dart';
import 'package:sanadi/features/grocery/model/grocery_product_model.dart';
import 'package:sanadi/features/grocery/model/product_review_model.dart';

class GroceryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _categoriesRef =>
      _firestore.collection('grocery_categories');
  CollectionReference get _productsRef =>
      _firestore.collection('grocery_products');
  CollectionReference get _ordersRef =>
      _firestore.collection('orders'); // ✅ تغيير من grocery_orders
  CollectionReference get _reviewsRef =>
      _firestore.collection('product_reviews');

  // User cart reference
  CollectionReference _cartRef(String uid) => // ✅ تغيير من userId
      _firestore.collection('users').doc(uid).collection('cart');

  // ============================================
  // Categories
  // ============================================

  /// Get all active categories
  Future<List<GroceryCategoryModel>> getCategories() async {
    try {
      debugPrint('🔍 Fetching categories...');

      final snapshot =
          await _categoriesRef.where('isActive', isEqualTo: true).get();

      debugPrint('✅ Found ${snapshot.docs.length} categories');

      final categories = snapshot.docs
          .map((doc) => GroceryCategoryModel.fromFirestore(doc))
          .toList();

      categories.sort((a, b) => a.order.compareTo(b.order));

      return categories;
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      return [];
    }
  }

  /// Get category by ID
  Future<GroceryCategoryModel?> getCategoryById(String categoryId) async {
    try {
      final doc = await _categoriesRef.doc(categoryId).get();
      if (!doc.exists) return null;
      return GroceryCategoryModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting category: $e');
      return null;
    }
  }

  // ============================================
  // Products
  // ============================================

  /// Get products by category
  Future<List<GroceryProductModel>> getProductsByCategory(
    String categoryId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _productsRef
          .where('categoryId', isEqualTo: categoryId)
          .where('isAvailable', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GroceryProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading products: $e');
      return [];
    }
  }

  /// Get all available products
  Future<List<GroceryProductModel>> getAllProducts({int limit = 100}) async {
    try {
      final snapshot = await _productsRef
          .where('isAvailable', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GroceryProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading all products: $e');
      return [];
    }
  }

  /// Get products with discounts
  Future<List<GroceryProductModel>> getDiscountedProducts(
      {int limit = 10}) async {
    try {
      final snapshot = await _productsRef
          .where('isAvailable', isEqualTo: true)
          .where('oldPrice', isGreaterThan: 0)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GroceryProductModel.fromFirestore(doc))
          .where((p) => p.hasDiscount)
          .toList();
    } catch (e) {
      debugPrint('Error loading discounted products: $e');
      return [];
    }
  }

  /// Get product by ID
  Future<GroceryProductModel?> getProductById(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).get();
      if (!doc.exists) return null;
      return GroceryProductModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }

  /// Search products
  Future<List<GroceryProductModel>> searchProducts(
    String query, {
    String? categoryId,
    int limit = 50,
  }) async {
    try {
      if (query.isEmpty) {
        if (categoryId != null) {
          return getProductsByCategory(categoryId);
        }
        return getAllProducts();
      }

      final allProducts = categoryId != null
          ? await getProductsByCategory(categoryId, limit: 500)
          : await getAllProducts(limit: 500);

      final queryLower = query.toLowerCase();
      return allProducts.where((product) {
        return product.nameAr.toLowerCase().contains(queryLower) ||
            product.nameEn.toLowerCase().contains(queryLower) ||
            product.descriptionAr.toLowerCase().contains(queryLower) ||
            product.descriptionEn.toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }

  /// Update product stock
  Future<bool> updateProductStock(
      String productId, int quantityToReduce) async {
    try {
      final productDoc = _productsRef.doc(productId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productDoc);
        if (!snapshot.exists) {
          throw Exception('Product not found');
        }

        final currentStock = snapshot.get('stockQuantity') as int;
        final newStock = currentStock - quantityToReduce;

        if (newStock < 0) {
          throw Exception('Insufficient stock');
        }

        transaction.update(productDoc, {
          'stockQuantity': newStock,
          'isAvailable': newStock > 0,
        });
      });

      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  // ============================================
  // Cart
  // ============================================

  /// Get user's cart items
  Future<List<CartItemModel>> getCartItems(String uid) async {
    // ✅ تغيير من userId
    try {
      final snapshot = await _cartRef(uid).get();

      final items =
          snapshot.docs.map((doc) => CartItemModel.fromFirestore(doc)).toList();

      items.sort((a, b) {
        if (a.addedAt == null || b.addedAt == null) return 0;
        return b.addedAt!.compareTo(a.addedAt!);
      });

      return items;
    } catch (e) {
      debugPrint('Error loading cart: $e');
      return [];
    }
  }

  /// Add item to cart
  Future<CartItemModel?> addToCart(String uid, CartItemModel item) async {
    // ✅ تغيير من userId
    try {
      final existing = await _cartRef(uid)
          .where('productId', isEqualTo: item.productId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final existingItem = CartItemModel.fromFirestore(existing.docs.first);
        return await updateCartItemQuantity(
          uid,
          existing.docs.first.id,
          existingItem.quantity + item.quantity,
        );
      }

      final docRef = await _cartRef(uid).add(item.toMap());
      return item.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      return null;
    }
  }

  /// Update cart item quantity
  Future<CartItemModel?> updateCartItemQuantity(
    String uid, // ✅ تغيير من userId
    String itemId,
    int quantity,
  ) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(uid, itemId);
        return null;
      }

      await _cartRef(uid).doc(itemId).update({'quantity': quantity});

      final doc = await _cartRef(uid).doc(itemId).get();
      return CartItemModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error updating cart item: $e');
      return null;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(String uid, String itemId) async {
    // ✅ تغيير من userId
    try {
      await _cartRef(uid).doc(itemId).delete();
      return true;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }

  /// Clear cart
  Future<bool> clearCart(String uid) async {
    // ✅ تغيير من userId
    try {
      final snapshot = await _cartRef(uid).get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      return false;
    }
  }

  /// Get cart items count
  Future<int> getCartItemsCount(String uid) async {
    // ✅ تغيير من userId
    try {
      final snapshot = await _cartRef(uid).get();
      int count = 0;
      for (var doc in snapshot.docs) {
        count += (doc.data() as Map<String, dynamic>)['quantity'] as int;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  // ============================================
  // Orders
  // ============================================

  /// Generate order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = now.millisecondsSinceEpoch.toString().substring(8);
    return 'ORD-$date-$random';
  }

  /// Create order
  Future<GroceryOrderModel?> createOrder({
    required String uid, // ✅ تغيير من userId إلى uid
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    required List<CartItemModel> items,
    String? notes,
  }) async {
    try {
      // Validate stock availability
      for (var item in items) {
        final product = await getProductById(item.productId);
        if (product == null || !product.isInStock) {
          throw Exception('${item.getName('ar')} غير متاح');
        }
        if (product.stockQuantity < item.quantity) {
          throw Exception(
              'الكمية المطلوبة من ${item.getName('ar')} غير متوفرة');
        }
      }

      // Calculate totals
      final subtotal =
          items.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final totalAmount = subtotal;

      // Create order items
      final orderItems = items
          .map((item) => OrderItemModel(
                productId: item.productId,
                nameAr: item.nameAr ?? '',
                nameEn: item.nameEn ?? '',
                imageUrl: item.imageUrl ?? '',
                quantity: item.quantity,
                price: item.price,
                unit: item.unit ?? 'piece',
                total: item.totalPrice,
              ))
          .toList();

      // Create order
      final order = GroceryOrderModel(
        id: '',
        orderNumber: _generateOrderNumber(),
        uid: uid, // ✅ تغيير من userId إلى uid
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        items: orderItems,
        subtotal: subtotal,
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        notes: notes,
        whatsappSent: false,
        createdAt: DateTime.now(),
      );

      // Save order
      final docRef = await _ordersRef.add(order.toMap());

      // Clear cart
      await clearCart(uid);

      return order.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  /// Get user orders
  Future<List<GroceryOrderModel>> getUserOrders(
    String uid, {
    // ✅ تغيير من userId إلى uid
    int limit = 50,
  }) async {
    try {
      final snapshot = await _ordersRef
          .where('uid', isEqualTo: uid) // ✅ تغيير من userId إلى uid
          .limit(limit)
          .get();

      final orders = snapshot.docs
          .map((doc) => GroceryOrderModel.fromFirestore(doc))
          .toList();

      orders.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return orders;
    } catch (e) {
      debugPrint('Error loading orders: $e');
      return [];
    }
  }

  /// Get order by ID
  Future<GroceryOrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (!doc.exists) return null;
      return GroceryOrderModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  /// Update order status (for admin/backend)
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _ordersRef.doc(orderId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  /// Mark WhatsApp as sent
  Future<bool> markWhatsAppSent(String orderId) async {
    try {
      await _ordersRef.doc(orderId).update({'whatsappSent': true});
      return true;
    } catch (e) {
      debugPrint('Error marking WhatsApp sent: $e');
      return false;
    }
  }

  // ============================================
  // Reviews
  // ============================================

  /// Get product reviews
  Future<List<ProductReviewModel>> getProductReviews(
    String productId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _reviewsRef
          .where('productId', isEqualTo: productId)
          .limit(limit)
          .get();

      final reviews = snapshot.docs
          .map((doc) => ProductReviewModel.fromFirestore(doc))
          .toList();

      reviews.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return reviews;
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      return [];
    }
  }

  /// Add review
  Future<ProductReviewModel?> addReview({
    required String productId,
    required String uid, // ✅ تغيير من userId
    required String userName,
    String? userPhoto,
    required int rating,
    String? comment,
    String? orderId,
  }) async {
    try {
      final existing = await _reviewsRef
          .where('productId', isEqualTo: productId)
          .where('uid', isEqualTo: uid) // ✅ تغيير من userId
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return await updateReview(
          reviewId: existing.docs.first.id,
          rating: rating,
          comment: comment,
        );
      }

      final review = ProductReviewModel(
        id: '',
        productId: productId,
        userId: uid, // ملاحظة: ProductReviewModel قد يحتاج تعديل أيضاً
        userName: userName,
        userPhoto: userPhoto,
        rating: rating,
        comment: comment,
        orderId: orderId,
        isVerifiedPurchase: orderId != null,
        createdAt: DateTime.now(),
      );

      final docRef = await _reviewsRef.add(review.toMap());

      await _updateProductRating(productId);

      return review.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Error adding review: $e');
      return null;
    }
  }

  /// Update review
  Future<ProductReviewModel?> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _reviewsRef.doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final doc = await _reviewsRef.doc(reviewId).get();
      final review = ProductReviewModel.fromFirestore(doc);

      await _updateProductRating(review.productId);

      return review;
    } catch (e) {
      debugPrint('Error updating review: $e');
      return null;
    }
  }

  /// Delete review
  Future<bool> deleteReview(String reviewId, String productId) async {
    try {
      await _reviewsRef.doc(reviewId).delete();
      await _updateProductRating(productId);
      return true;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Check if user reviewed product
  Future<bool> hasUserReviewedProduct(String productId, String uid) async {
    // ✅ تغيير من userId
    try {
      final snapshot = await _reviewsRef
          .where('productId', isEqualTo: productId)
          .where('uid', isEqualTo: uid) // ✅ تغيير من userId
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Update product rating statistics
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviews = await getProductReviews(productId, limit: 1000);

      if (reviews.isEmpty) {
        await _productsRef.doc(productId).update({
          'rating': 0.0,
          'reviewsCount': 0,
        });
        return;
      }

      final totalRating = reviews.fold<int>(0, (sum, r) => sum + r.rating);
      final averageRating = totalRating / reviews.length;

      await _productsRef.doc(productId).update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'reviewsCount': reviews.length,
      });
    } catch (e) {
      debugPrint('Error updating product rating: $e');
    }
  }

  // ============================================
  // Order History (Purchased Items)
  // ============================================

  /// Get all purchased items from order history
  Future<List<OrderItemModel>> getPurchasedItems(
    String uid, {
    // ✅ تغيير من userId
    String? categoryId,
  }) async {
    try {
      final orders = await getUserOrders(uid, limit: 100);

      final allItems = <OrderItemModel>[];
      for (var order in orders) {
        if (order.status != OrderStatus.cancelled) {
          allItems.addAll(order.items);
        }
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        final filteredItems = <OrderItemModel>[];
        for (var item in allItems) {
          final product = await getProductById(item.productId);
          if (product != null && product.categoryId == categoryId) {
            filteredItems.add(item);
          }
        }
        return filteredItems;
      }

      return allItems;
    } catch (e) {
      debugPrint('Error getting purchased items: $e');
      return [];
    }
  }
}
