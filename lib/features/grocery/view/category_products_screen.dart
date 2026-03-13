import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/features/grocery/model/grocery_category_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../services/firestore/supabase_storage_service.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import '../viewmodel/grocery_cubit.dart';
import '../viewmodel/grocery_state.dart';
import '../viewmodel/cart_cubit.dart';
import '../viewmodel/cart_state.dart';
import '../model/grocery_product_model.dart';
import '../model/cart_item_model.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<GroceryProductModel> _searchResults = [];
  List<GroceryCategoryModel> _searchCategoryResults = [];

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(BuildContext context, String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchCategoryResults = [];
      });
      context.read<CategoryProductsCubit>().clearSearch();
      return;
    }

    setState(() => _isSearching = true);

    // Call global search from GroceryCubit
    final productResults =
        await context.read<GroceryCubit>().searchProducts(query);

    // Search categories locally from GroceryCubit state if loaded
    final groceryState = context.read<GroceryCubit>().state;
    List<GroceryCategoryModel> categoryResults = [];
    if (groceryState is GroceryLoaded) {
      final queryLower = query.toLowerCase();
      categoryResults = groceryState.categories.where((cat) {
        return cat.nameAr.toLowerCase().contains(queryLower) ||
            cat.nameEn.toLowerCase().contains(queryLower);
      }).toList();
    }

    setState(() {
      _searchResults = productResults;
      _searchCategoryResults = categoryResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return BlocProvider(
      create: (context) =>
          CategoryProductsCubit()..loadProducts(widget.categoryId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, isLarge),
        body: SafeArea(
          child: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
            builder: (context, state) {
              if (state is CategoryProductsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (state is CategoryProductsError) {
                return _buildErrorWidget(context, state.message, isLarge);
              }

              if (state is CategoryProductsLoaded) {
                return _isSearching
                    ? _buildSearchResults(isLarge, lang)
                    : _buildContent(context, state, isLarge, lang);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isLarge) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
        builder: (context, state) {
          String title = 'grocery.products'.tr();
          if (state is CategoryProductsLoaded) {
            title = state.category.getName(context.locale.languageCode);
          }
          return Text(
            title,
            style: TextStyle(
              fontSize: isLarge ? 20 : 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          );
        },
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            int itemCount = 0;
            if (state is CartLoaded) {
              itemCount = state.totalItems;
            }

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.textPrimary),
                  onPressed: () => context.pushFadeSlide(const CartScreen()),
                ),
                if (itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w,
                        minHeight: 16.h,
                      ),
                      child: Text(
                        itemCount > 99 ? '99+' : '$itemCount',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    CategoryProductsLoaded state,
    bool isLarge,
    String lang,
  ) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(isLarge ? 24 : 16.w),
          child: _buildSearchBar(context, isLarge),
        ),

        // Products count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
          child: Row(
            children: [
              Text(
                '${state.filteredProducts.length} ${'grocery.products'.tr()}',
                style: TextStyle(
                  fontSize: isLarge ? 15 : 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isLarge ? 16 : 12.h),

        // Products Grid
        Expanded(
          child: state.filteredProducts.isEmpty
              ? _buildEmptyState(isLarge)
              : GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLarge ? 24 : 16.w,
                    vertical: isLarge ? 8 : 4.h,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isLarge ? 4 : 2,
                    childAspectRatio: isLarge ? 0.75 : 0.68,
                    crossAxisSpacing: isLarge ? 16 : 12.w,
                    mainAxisSpacing: isLarge ? 16 : 12.h,
                  ),
                  itemCount: state.filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(
                      context,
                      state.filteredProducts[index],
                      isLarge,
                      lang,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isLarge) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) => _onSearch(context, query),
        decoration: InputDecoration(
          hintText: 'grocery.search_hint'.tr(),
          hintStyle: TextStyle(
            color: AppColors.textHint,
            fontSize: isLarge ? 15 : 14.sp,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: isLarge ? 24 : 22.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: isLarge ? 22 : 20.sp),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch(context, '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isLarge ? 20 : 16.w,
            vertical: isLarge ? 16 : 14.h,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    GroceryProductModel product,
    bool isLarge,
    String lang,
  ) {
    return GestureDetector(
      onTap: () =>
          context.pushFadeSlide(ProductDetailsScreen(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.lightGrey,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.lightGrey,
                        child: Icon(Icons.image, size: 40.sp),
                      ),
                    ),
                  ),

                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: lang == 'ar' ? null : 8,
                      right: lang == 'ar' ? 8 : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: isLarge ? 11 : 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Out of stock overlay
                  if (!product.isInStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'grocery.out_of_stock'.tr(),
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: isLarge ? 13 : 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isLarge ? 12 : 8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      product.getName(lang),
                      style: TextStyle(
                        fontSize: isLarge ? 14 : 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),

                    // Unit
                    Text(
                      product.getUnitDisplay(lang),
                      style: TextStyle(
                        fontSize: isLarge ? 12 : 10.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const Spacer(),

                    // Price and Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${product.formattedPrice} ${'grocery.currency'.tr()}',
                              style: TextStyle(
                                fontSize: isLarge ? 14 : 12.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (product.hasDiscount)
                              Text(
                                product.formattedOldPrice,
                                style: TextStyle(
                                  fontSize: isLarge ? 10 : 9.sp,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),

                        // Add to cart button
                        if (product.isInStock)
                          GestureDetector(
                            onTap: () => _addToCart(context, product),
                            child: Container(
                              padding: EdgeInsets.all(isLarge ? 8 : 6.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: AppColors.white,
                                size: isLarge ? 20 : 18.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isLarge, String lang) {
    final hasCategories = _searchCategoryResults.isNotEmpty;
    final hasProducts = _searchResults.isNotEmpty;

    if (!hasCategories && !hasProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64.sp, color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text(
              'grocery.no_results'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 18 : 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isLarge ? 24 : 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Results
          if (hasCategories) ...[
            Text(
              'grocery.categories'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 20 : 17.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLarge ? 4 : 2,
                childAspectRatio: isLarge ? 1.1 : 1.0,
                crossAxisSpacing: isLarge ? 16 : 12.w,
                mainAxisSpacing: isLarge ? 16 : 12.h,
              ),
              itemCount: _searchCategoryResults.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(
                  _searchCategoryResults[index],
                  isLarge,
                  lang,
                );
              },
            ),
            SizedBox(height: 24.h),
          ],

          // Products Results
          if (hasProducts) ...[
            Text(
              'grocery.products'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 20 : 17.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLarge ? 4 : 2,
                childAspectRatio: isLarge ? 0.75 : 0.68,
                crossAxisSpacing: isLarge ? 16 : 12.w,
                mainAxisSpacing: isLarge ? 16 : 12.h,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  context,
                  _searchResults[index],
                  isLarge,
                  lang,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    GroceryCategoryModel category,
    bool isLarge,
    String lang,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          AppPageTransitions.slideRight(
            CategoryProductsScreen(categoryId: category.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Color(category.colorValue).withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: SupabaseStorageService.getGroceryCategoryImage(
                        category.image),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Icon(
                        Icons.category,
                        size: isLarge ? 32 : 28.sp,
                        color: Color(category.colorValue),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.category,
                        size: isLarge ? 32 : 28.sp,
                        color: Color(category.colorValue),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 12.h),
              child: Text(
                category.getName(lang),
                style: TextStyle(
                  fontSize: isLarge ? 15 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, GroceryProductModel product) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    context.read<CartCubit>().addToCart(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('grocery.added_to_cart'.tr()),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'grocery.view_cart'.tr(),
          textColor: AppColors.white,
          onPressed: () => context.pushFadeSlide(const CartScreen()),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLarge) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: isLarge ? 80 : 64.sp,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16.h),
          Text(
            'grocery.no_products'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 18 : 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message, bool isLarge) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              context
                  .read<CategoryProductsCubit>()
                  .loadProducts(widget.categoryId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('grocery.retry'.tr()),
          ),
        ],
      ),
    );
  }
}
