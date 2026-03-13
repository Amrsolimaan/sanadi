import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanadi/services/firestore/grocery_service.dart';
import '../model/grocery_category_model.dart';
import '../model/grocery_product_model.dart';
import '../model/cart_item_model.dart';
import 'grocery_state.dart';

class GroceryCubit extends Cubit<GroceryState> {
  final GroceryService _groceryService = GroceryService();

  GroceryCubit() : super(GroceryInitial());

  /// Load categories and discounted products
  Future<void> loadGroceryData() async {
    emit(GroceryLoading());

    try {
      final categories = await _groceryService.getCategories();
      final discountedProducts = await _groceryService.getDiscountedProducts();
      final allProducts = await _groceryService.getAllProducts();

      emit(GroceryLoaded(
        categories: categories,
        discountedProducts: discountedProducts,
        allProducts: allProducts,
      ));
    } catch (e) {
      emit(GroceryError(message: e.toString()));
    }
  }

  /// Search all products
  Future<List<GroceryProductModel>> searchProducts(String query) async {
    return await _groceryService.searchProducts(query);
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadGroceryData();
  }
}

// ============================================
// Category Products Cubit
// ============================================

class CategoryProductsCubit extends Cubit<CategoryProductsState> {
  final GroceryService _groceryService = GroceryService();

  CategoryProductsCubit() : super(CategoryProductsInitial());

  /// Load products for a category
  Future<void> loadProducts(String categoryId) async {
    emit(CategoryProductsLoading());

    try {
      final category = await _groceryService.getCategoryById(categoryId);
      if (category == null) {
        emit(const CategoryProductsError(message: 'Category not found'));
        return;
      }

      final products = await _groceryService.getProductsByCategory(categoryId);

      emit(CategoryProductsLoaded(
        category: category,
        products: products,
        filteredProducts: products,
      ));
    } catch (e) {
      emit(CategoryProductsError(message: e.toString()));
    }
  }

  /// Search products in category
  void searchProducts(String query) {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;

      if (query.isEmpty) {
        emit(currentState.copyWith(
          filteredProducts: currentState.products,
          searchQuery: '',
        ));
        return;
      }

      final queryLower = query.toLowerCase();
      final filtered = currentState.products.where((product) {
        return product.nameAr.toLowerCase().contains(queryLower) ||
            product.nameEn.toLowerCase().contains(queryLower);
      }).toList();

      emit(currentState.copyWith(
        filteredProducts: filtered,
        searchQuery: query,
      ));
    }
  }

  /// Clear search
  void clearSearch() {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      emit(currentState.copyWith(
        filteredProducts: currentState.products,
        searchQuery: '',
      ));
    }
  }
}

// ============================================
// Product Details Cubit
// ============================================

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final GroceryService _groceryService = GroceryService();

  ProductDetailsCubit() : super(ProductDetailsInitial());

  /// Load product details
  Future<void> loadProduct(String productId) async {
    emit(ProductDetailsLoading());

    try {
      final product = await _groceryService.getProductById(productId);
      if (product == null) {
        emit(const ProductDetailsError(message: 'Product not found'));
        return;
      }

      emit(ProductDetailsLoaded(product: product));
    } catch (e) {
      emit(ProductDetailsError(message: e.toString()));
    }
  }

  /// Load product directly
  void setProduct(GroceryProductModel product) {
    emit(ProductDetailsLoaded(product: product));
  }

  /// Increase quantity
  void increaseQuantity() {
    if (state is ProductDetailsLoaded) {
      final currentState = state as ProductDetailsLoaded;
      final maxQuantity = currentState.product.stockQuantity;

      if (currentState.quantity < maxQuantity) {
        emit(currentState.copyWith(quantity: currentState.quantity + 1));
      }
    }
  }

  /// Decrease quantity
  void decreaseQuantity() {
    if (state is ProductDetailsLoaded) {
      final currentState = state as ProductDetailsLoaded;

      if (currentState.quantity > 1) {
        emit(currentState.copyWith(quantity: currentState.quantity - 1));
      }
    }
  }

  /// Set quantity
  void setQuantity(int quantity) {
    if (state is ProductDetailsLoaded) {
      final currentState = state as ProductDetailsLoaded;
      final maxQuantity = currentState.product.stockQuantity;

      if (quantity >= 1 && quantity <= maxQuantity) {
        emit(currentState.copyWith(quantity: quantity));
      }
    }
  }

  /// Add to cart
  Future<void> addToCart(String userId) async {
    if (state is ProductDetailsLoaded) {
      final currentState = state as ProductDetailsLoaded;
      emit(currentState.copyWith(isAddingToCart: true));

      try {
        final cartItem = CartItemModel.fromProduct(
          currentState.product,
          quantity: currentState.quantity,
        );

        await _groceryService.addToCart(userId, cartItem);

        emit(ProductAddedToCart(
          product: currentState.product,
          quantity: currentState.quantity,
        ));

        // Reset to loaded state
        emit(ProductDetailsLoaded(product: currentState.product));
      } catch (e) {
        emit(currentState.copyWith(isAddingToCart: false));
        emit(ProductDetailsError(message: e.toString()));
      }
    }
  }
}
