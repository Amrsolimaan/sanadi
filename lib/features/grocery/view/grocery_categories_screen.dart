import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../model/grocery_category_model.dart';
import '../model/grocery_product_model.dart';
import 'category_products_screen.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';
import 'all_products_screen.dart';

class GroceryCategoriesScreen extends StatefulWidget {
  const GroceryCategoriesScreen({super.key});

  @override
  State<GroceryCategoriesScreen> createState() =>
      _GroceryCategoriesScreenState();
}

class _GroceryCategoriesScreenState extends State<GroceryCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<GroceryProductModel> _searchResults = [];
  List<GroceryCategoryModel> _searchCategoryResults = [];
  bool _isAllProductsButtonPressed = false;
  bool _isSearchBarFocused = false;

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchFocusNode.addListener(_onFocusChange);
  }

  void _loadData() {
    context.read<GroceryCubit>().loadGroceryData();

    // Set user for cart
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<CartCubit>().setUser(authState.user.uid);
    }
  }

  void _onFocusChange() {
    setState(() {
      _isSearchBarFocused = _searchFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchResults = [];
      _searchCategoryResults = [];
    });
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchCategoryResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final state = context.read<GroceryCubit>().state;
    if (state is GroceryLoaded) {
      // البحث في المنتجات
      final productResults =
          await context.read<GroceryCubit>().searchProducts(query);
      
      // البحث في التصنيفات بدقة أعلى
      final queryLower = query.trim().toLowerCase();
      final categoryResults = state.categories.where((cat) {
        final nameAr = cat.nameAr.toLowerCase();
        final nameEn = cat.nameEn.toLowerCase();
        
        // البحث الدقيق: يبدأ بالكلمة أو يحتوي عليها
        return nameAr.contains(queryLower) || 
               nameEn.contains(queryLower) ||
               nameAr.split(' ').any((word) => word.startsWith(queryLower)) ||
               nameEn.split(' ').any((word) => word.startsWith(queryLower));
      }).toList();

      // ترتيب النتائج حسب الأولوية
      categoryResults.sort((a, b) {
        final aNameAr = a.nameAr.toLowerCase();
        final aNameEn = a.nameEn.toLowerCase();
        final bNameAr = b.nameAr.toLowerCase();
        final bNameEn = b.nameEn.toLowerCase();
        
        // الأولوية للنتائج التي تبدأ بالكلمة المبحوث عنها
        final aStartsWith = aNameAr.startsWith(queryLower) || aNameEn.startsWith(queryLower);
        final bStartsWith = bNameAr.startsWith(queryLower) || bNameEn.startsWith(queryLower);
        
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        
        return 0;
      });

      setState(() {
        _searchResults = productResults;
        _searchCategoryResults = categoryResults;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isLarge),
      body: SafeArea(
        child: BlocBuilder<GroceryCubit, GroceryState>(
          builder: (context, state) {
            if (state is GroceryLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is GroceryError) {
              return _buildErrorWidget(state.message, isLarge);
            }

            if (state is GroceryLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<GroceryCubit>().refresh();
                },
                child: _isSearching
                    ? _buildSearchResults(isLarge, lang)
                    : _buildMainContent(state, isLarge, lang),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLarge) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: _clearSearch,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
      title: Text(
        _isSearching ? 'grocery.search'.tr() : 'grocery.title'.tr(),
        style: TextStyle(
          fontSize: isLarge ? 20 : 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_isSearching)
          TextButton(
            onPressed: _clearSearch,
            child: Text(
              'grocery.cancel'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 15 : 14.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
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

  Widget _buildMainContent(GroceryLoaded state, bool isLarge, String lang) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLarge ? 32 : 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          _buildSearchBar(isLarge),
          SizedBox(height: isLarge ? 24 : 16.h),

          // Categories Title with "View All Products" Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'grocery.categories'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 22 : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTapDown: (_) =>
                    setState(() => _isAllProductsButtonPressed = true),
                onTapUp: (_) {
                  setState(() => _isAllProductsButtonPressed = false);
                  _viewAllProducts(state.allProducts);
                },
                onTapCancel: () =>
                    setState(() => _isAllProductsButtonPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()
                    ..scale(_isAllProductsButtonPressed ? 0.95 : 1.0),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: _isAllProductsButtonPressed
                        ? AppColors.lightGrey.withOpacity(0.5)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'grocery.all_products'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 16 : 12.h),

          // Categories Grid
          _buildCategoriesGrid(state.categories, isLarge, lang),

          // Discounted Products
          if (state.discountedProducts.isNotEmpty) ...[
            SizedBox(height: isLarge ? 32 : 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'grocery.todays_deals'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 22 : 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(Icons.local_fire_department,
                    color: AppColors.error, size: isLarge ? 28 : 24.sp),
              ],
            ),
            SizedBox(height: isLarge ? 16 : 12.h),
            _buildDealsSection(state.discountedProducts, isLarge, lang),
          ],

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  void _viewAllProducts(List<GroceryProductModel> products) {
    Navigator.push(
      context,
      AppPageTransitions.slideRight(
        AllProductsScreen(products: products),
      ),
    );
  }

  Widget _buildSearchBar(bool isLarge) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSearchBarFocused ? AppColors.primary : AppColors.lightGrey,
          width: _isSearchBarFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchBarFocused 
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: _isSearchBarFocused ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearch,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'grocery.search_products_categories'.tr(),
          hintStyle: TextStyle(
            color: AppColors.textHint,
            fontSize: isLarge ? 15 : 14.sp,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _isSearchBarFocused ? AppColors.primary : AppColors.textSecondary,
            size: isLarge ? 24 : 22.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: isLarge ? 22 : 20.sp,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _clearSearch,
                      tooltip: 'grocery.clear_search'.tr(),
                    ),
                  ],
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

  Widget _buildCategoriesGrid(
      List<GroceryCategoryModel> categories, bool isLarge, String lang) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLarge ? 4 : 2, // Changed from 3 to 2
        childAspectRatio: isLarge ? 1.1 : 1.0, // Adjusted ratio
        crossAxisSpacing: isLarge ? 16 : 12.w,
        mainAxisSpacing: isLarge ? 16 : 12.h,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, isLarge, lang);
      },
    );
  }

  Widget _buildCategoryCard(
      GroceryCategoryModel category, bool isLarge, String lang) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageTransitions.slideRight(
          CategoryProductsScreen(categoryId: category.id),
        ),
      ),
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
            // Category Image - Full Coverage
            Expanded(
              flex: 4, // Increased from 3
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

            // Category Name - More space
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

  Widget _buildDealsSection(
      List<GroceryProductModel> products, bool isLarge, String lang) {
    return SizedBox(
      height: isLarge ? 220 : 200.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: isLarge ? 16 : 12.w),
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildDealCard(product, isLarge, lang);
        },
      ),
    );
  }

  Widget _buildDealCard(
      GroceryProductModel product, bool isLarge, String lang) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageTransitions.slideRight(
          ProductDetailsScreen(product: product),
        ),
      ),
      child: Container(
        width: isLarge ? 180 : 150.w,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    height: isLarge ? 110 : 100.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.lightGrey,
                      child: Icon(Icons.image, size: 40.sp),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.lightGrey,
                      child: Icon(Icons.image, size: 40.sp),
                    ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: lang == 'ar' ? null : 8,
                    right: lang == 'ar' ? 8 : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${product.discountPercentage}%',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: isLarge ? 12 : 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: EdgeInsets.all(isLarge ? 12 : 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.getName(lang),
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Price
                  Row(
                    children: [
                      Text(
                        '${product.formattedPrice} ${'grocery.currency'.tr()}',
                        style: TextStyle(
                          fontSize: isLarge ? 14 : 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        SizedBox(width: 6.w),
                        Text(
                          product.formattedOldPrice,
                          style: TextStyle(
                            fontSize: isLarge ? 11 : 10.sp,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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
        child: Padding(
          padding: EdgeInsets.all(isLarge ? 32 : 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: isLarge ? 80 : 64.sp,
                color: AppColors.textHint,
              ),
              SizedBox(height: 16.h),
              Text(
                'grocery.no_results'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 18 : 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'grocery.try_different_search'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 14 : 13.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              OutlinedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear_all),
                label: Text('grocery.clear_search'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isLarge ? 32 : 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Summary
          Container(
            padding: EdgeInsets.all(isLarge ? 16 : 12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isLarge ? 20 : 18.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'grocery.found_results'.tr(namedArgs: {
                      'categories': _searchCategoryResults.length.toString(),
                      'products': _searchResults.length.toString(),
                    }),
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 13.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Categories Results
          if (hasCategories) ...[
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: isLarge ? 22 : 20.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'grocery.categories'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _searchCategoryResults.length.toString(),
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
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
                    _searchCategoryResults[index], isLarge, lang);
              },
            ),
            SizedBox(height: 24.h),
          ],

          // Products Results
          if (hasProducts) ...[
            Row(
              children: [
                Icon(
                  Icons.shopping_bag,
                  size: isLarge ? 22 : 20.sp,
                  color: AppColors.secondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'grocery.products'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 17.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _searchResults.length.toString(),
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLarge ? 4 : 2,
                childAspectRatio: isLarge ? 0.85 : 0.75,
                crossAxisSpacing: isLarge ? 16 : 12.w,
                mainAxisSpacing: isLarge ? 16 : 12.h,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_searchResults[index], isLarge, lang);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(
      GroceryProductModel product, bool isLarge, String lang) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppPageTransitions.slideRight(
          ProductDetailsScreen(product: product),
        ),
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.lightGrey,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.lightGrey,
                        child: Icon(Icons.image, size: 40.sp),
                      ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: lang == 'ar' ? null : 8,
                      right: lang == 'ar' ? 8 : null,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercentage}%',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: isLarge ? 11 : 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isLarge ? 12 : 10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.getName(lang),
                      style: TextStyle(
                        fontSize: isLarge ? 14 : 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.formattedPrice} ${'grocery.currency'.tr()}',
                          style: TextStyle(
                            fontSize: isLarge ? 14 : 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.hasDiscount)
                          Text(
                            product.formattedOldPrice,
                            style: TextStyle(
                              fontSize: isLarge ? 11 : 10.sp,
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
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

  Widget _buildErrorWidget(String message, bool isLarge) {
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
            onPressed: _loadData,
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
