import 'package:equatable/equatable.dart';
import '../model/grocery_category_model.dart';
import '../model/grocery_product_model.dart';

abstract class GroceryState extends Equatable {
  const GroceryState();

  @override
  List<Object?> get props => [];
}

class GroceryInitial extends GroceryState {}

class GroceryLoading extends GroceryState {}

class GroceryLoaded extends GroceryState {
  final List<GroceryCategoryModel> categories;
  final List<GroceryProductModel> discountedProducts;
  final List<GroceryProductModel> allProducts;

  const GroceryLoaded({
    required this.categories,
    this.discountedProducts = const [],
    this.allProducts = const [],
  });

  @override
  List<Object?> get props => [categories, discountedProducts, allProducts];

  GroceryLoaded copyWith({
    List<GroceryCategoryModel>? categories,
    List<GroceryProductModel>? discountedProducts,
    List<GroceryProductModel>? allProducts,
  }) {
    return GroceryLoaded(
      categories: categories ?? this.categories,
      discountedProducts: discountedProducts ?? this.discountedProducts,
      allProducts: allProducts ?? this.allProducts,
    );
  }
}

class GroceryError extends GroceryState {
  final String message;

  const GroceryError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============================================
// Category Products State
// ============================================

abstract class CategoryProductsState extends Equatable {
  const CategoryProductsState();

  @override
  List<Object?> get props => [];
}

class CategoryProductsInitial extends CategoryProductsState {}

class CategoryProductsLoading extends CategoryProductsState {}

class CategoryProductsLoaded extends CategoryProductsState {
  final GroceryCategoryModel category;
  final List<GroceryProductModel> products;
  final List<GroceryProductModel> filteredProducts;
  final String searchQuery;

  const CategoryProductsLoaded({
    required this.category,
    required this.products,
    required this.filteredProducts,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [category, products, filteredProducts, searchQuery];

  CategoryProductsLoaded copyWith({
    GroceryCategoryModel? category,
    List<GroceryProductModel>? products,
    List<GroceryProductModel>? filteredProducts,
    String? searchQuery,
  }) {
    return CategoryProductsLoaded(
      category: category ?? this.category,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CategoryProductsError extends CategoryProductsState {
  final String message;

  const CategoryProductsError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ============================================
// Product Details State
// ============================================

abstract class ProductDetailsState extends Equatable {
  const ProductDetailsState();

  @override
  List<Object?> get props => [];
}

class ProductDetailsInitial extends ProductDetailsState {}

class ProductDetailsLoading extends ProductDetailsState {}

class ProductDetailsLoaded extends ProductDetailsState {
  final GroceryProductModel product;
  final int quantity;
  final bool isAddingToCart;

  const ProductDetailsLoaded({
    required this.product,
    this.quantity = 1,
    this.isAddingToCart = false,
  });

  @override
  List<Object?> get props => [product, quantity, isAddingToCart];

  ProductDetailsLoaded copyWith({
    GroceryProductModel? product,
    int? quantity,
    bool? isAddingToCart,
  }) {
    return ProductDetailsLoaded(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isAddingToCart: isAddingToCart ?? this.isAddingToCart,
    );
  }
}

class ProductDetailsError extends ProductDetailsState {
  final String message;

  const ProductDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProductAddedToCart extends ProductDetailsState {
  final GroceryProductModel product;
  final int quantity;

  const ProductAddedToCart({
    required this.product,
    required this.quantity,
  });

  @override
  List<Object?> get props => [product, quantity];
}
