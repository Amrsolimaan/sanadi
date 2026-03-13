import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../model/grocery_product_model.dart';
import 'product_details_screen.dart';

class AllProductsScreen extends StatefulWidget {
  final List<GroceryProductModel> products;

  const AllProductsScreen({
    super.key,
    required this.products,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<GroceryProductModel> _filteredProducts = [];
  String _sortBy = 'name'; // name, price_low, price_high, discount

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(widget.products);
    _sortProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(widget.products);
      } else {
        final queryLower = query.toLowerCase();
        _filteredProducts = widget.products.where((product) {
          return product.nameAr.toLowerCase().contains(queryLower) ||
              product.nameEn.toLowerCase().contains(queryLower);
        }).toList();
      }
      _sortProducts();
    });
  }

  void _sortProducts() {
    setState(() {
      switch (_sortBy) {
        case 'name':
          _filteredProducts.sort((a, b) => a.nameEn.compareTo(b.nameEn));
          break;
        case 'price_low':
          _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'discount':
          _filteredProducts.sort((a, b) {
            if (a.hasDiscount && !b.hasDiscount) return -1;
            if (!a.hasDiscount && b.hasDiscount) return 1;
            return b.discountPercentage.compareTo(a.discountPercentage);
          });
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isLarge),
      body: Column(
        children: [
          // Search and Filter Bar
          _buildSearchAndFilter(isLarge),

          // Products Count
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLarge ? 32 : 16.w,
              vertical: 12.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} ${'grocery.products'.tr()}',
                  style: TextStyle(
                    fontSize: isLarge ? 16 : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                _buildSortButton(isLarge),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState(isLarge)
                : _buildProductsGrid(isLarge, lang),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLarge) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'grocery.all_products'.tr(),
        style: TextStyle(
          fontSize: isLarge ? 20 : 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.lightGrey.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'grocery.search_products'.tr(),
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
                      _onSearch('');
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
      ),
    );
  }

  Widget _buildSortButton(bool isLarge) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _sortBy = value;
          _sortProducts();
        });
      },
      icon: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: isLarge ? 20 : 18.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'grocery.sort'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'name',
          child: Row(
            children: [
              Icon(
                _sortBy == 'name' ? Icons.check_circle : Icons.circle_outlined,
                size: 20.sp,
                color:
                    _sortBy == 'name' ? AppColors.primary : AppColors.textHint,
              ),
              SizedBox(width: 12.w),
              Text('grocery.sort_name'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'price_low',
          child: Row(
            children: [
              Icon(
                _sortBy == 'price_low'
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                size: 20.sp,
                color: _sortBy == 'price_low'
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              SizedBox(width: 12.w),
              Text('grocery.sort_price_low'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'price_high',
          child: Row(
            children: [
              Icon(
                _sortBy == 'price_high'
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                size: 20.sp,
                color: _sortBy == 'price_high'
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              SizedBox(width: 12.w),
              Text('grocery.sort_price_high'.tr()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'discount',
          child: Row(
            children: [
              Icon(
                _sortBy == 'discount'
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                size: 20.sp,
                color: _sortBy == 'discount'
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              SizedBox(width: 12.w),
              Text('grocery.sort_discount'.tr()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid(bool isLarge, String lang) {
    return GridView.builder(
      padding: EdgeInsets.all(isLarge ? 32 : 16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLarge ? 4 : 2, // Consistent 2 columns
        childAspectRatio:
            isLarge ? 0.85 : 0.70, // Adjusted for better proportions
        crossAxisSpacing: isLarge ? 16 : 12.w,
        mainAxisSpacing: isLarge ? 16 : 12.h,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index], isLarge, lang);
      },
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

  Widget _buildEmptyState(bool isLarge) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80.sp,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16.h),
          Text(
            'grocery.no_products_found'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 18 : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'grocery.try_different_search'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 14 : 13.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
