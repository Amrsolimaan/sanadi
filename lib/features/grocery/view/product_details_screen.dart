import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/services/firestore/grocery_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import '../viewmodel/grocery_cubit.dart';
import '../viewmodel/grocery_state.dart';
import '../viewmodel/cart_cubit.dart';
import '../model/grocery_product_model.dart';
import '../model/product_review_model.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final GroceryProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  bool _isAddingToCart = false;
  List<ProductReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final service = GroceryService();
    final reviews = await service.getProductReviews(widget.product.id);
    setState(() {
      _reviews = reviews;
      _isLoadingReviews = false;
    });
  }

  void _increaseQuantity() {
    if (_quantity < widget.product.stockQuantity) {
      HapticFeedback.lightImpact();
      setState(() => _quantity++);
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      HapticFeedback.lightImpact();
      setState(() => _quantity--);
    }
  }

  Future<void> _addToCart() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    setState(() => _isAddingToCart = true);

    await context
        .read<CartCubit>()
        .addToCart(widget.product, quantity: _quantity);

    setState(() => _isAddingToCart = false);

    if (mounted) {
      HapticFeedback.mediumImpact();
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
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;
    final product = widget.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(isLarge),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    _buildProductImage(product, isLarge, lang),

                    // Product Info
                    Padding(
                      padding: EdgeInsets.all(isLarge ? 24 : 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            product.getName(lang),
                            style: TextStyle(
                              fontSize: isLarge ? 24 : 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Rating
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < product.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppColors.warning,
                                  size: isLarge ? 22 : 18.sp,
                                );
                              }),
                              SizedBox(width: 8.w),
                              Text(
                                '${product.rating.toStringAsFixed(1)} (${product.reviewsCount} ${'grocery.reviews'.tr()})',
                                style: TextStyle(
                                  fontSize: isLarge ? 14 : 13.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Price
                          Row(
                            children: [
                              Text(
                                '${product.formattedPrice} ${'grocery.currency'.tr()}',
                                style: TextStyle(
                                  fontSize: isLarge ? 28 : 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (product.hasDiscount) ...[
                                SizedBox(width: 12.w),
                                Text(
                                  '${product.formattedOldPrice} ${'grocery.currency'.tr()}',
                                  style: TextStyle(
                                    fontSize: isLarge ? 18 : 16.sp,
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
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
                                      fontSize: isLarge ? 13 : 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),

                          // Unit
                          Text(
                            '${'grocery.per'.tr()} ${product.getUnitDisplay(lang)}',
                            style: TextStyle(
                              fontSize: isLarge ? 14 : 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Description Title
                          Text(
                            'grocery.description'.tr(),
                            style: TextStyle(
                              fontSize: isLarge ? 18 : 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Description
                          Text(
                            product.getDescription(lang),
                            style: TextStyle(
                              fontSize: isLarge ? 15 : 14.sp,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 20.h),

                          // Stock Status
                          Row(
                            children: [
                              Icon(
                                product.isInStock
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: product.isInStock
                                    ? AppColors.success
                                    : AppColors.error,
                                size: isLarge ? 22 : 18.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                product.isInStock
                                    ? '${'grocery.in_stock'.tr()} (${product.stockQuantity})'
                                    : 'grocery.out_of_stock'.tr(),
                                style: TextStyle(
                                  fontSize: isLarge ? 14 : 13.sp,
                                  color: product.isInStock
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // Quantity Selector
                          if (product.isInStock) ...[
                            Text(
                              'grocery.quantity'.tr(),
                              style: TextStyle(
                                fontSize: isLarge ? 16 : 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            _buildQuantitySelector(isLarge),
                          ],
                          SizedBox(height: 24.h),

                          // Reviews Section
                          _buildReviewsSection(isLarge, lang),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Add to Cart Button
            if (product.isInStock) _buildAddToCartButton(isLarge, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isLarge) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 8.w,
        vertical: 8.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon:
                const Icon(Icons.favorite_border, color: AppColors.textPrimary),
            onPressed: () {
              // Add to favorites
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(
      GroceryProductModel product, bool isLarge, String lang) {
    return Container(
      width: double.infinity,
      height: isLarge ? 350 : 280.h,
      margin: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: product.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.lightGrey,
                child:
                    Icon(Icons.image, size: 80.sp, color: AppColors.textHint),
              ),
            ),
          ),

          // Discount Badge
          if (product.hasDiscount)
            Positioned(
              top: 16,
              left: lang == 'ar' ? null : 16,
              right: lang == 'ar' ? 16 : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${product.discountPercentage}%',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: isLarge ? 16 : 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(bool isLarge) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease
          IconButton(
            onPressed: _quantity > 1 ? _decreaseQuantity : null,
            icon: Icon(
              Icons.remove,
              color: _quantity > 1 ? AppColors.primary : AppColors.textHint,
              size: isLarge ? 24 : 22.sp,
            ),
          ),

          // Quantity
          Container(
            padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 20.w),
            child: Text(
              '$_quantity',
              style: TextStyle(
                fontSize: isLarge ? 20 : 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Increase
          IconButton(
            onPressed: _quantity < widget.product.stockQuantity
                ? _increaseQuantity
                : null,
            icon: Icon(
              Icons.add,
              color: _quantity < widget.product.stockQuantity
                  ? AppColors.primary
                  : AppColors.textHint,
              size: isLarge ? 24 : 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(bool isLarge, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'grocery.reviews'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 18 : 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '(${_reviews.length})',
              style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_isLoadingReviews)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        else if (_reviews.isEmpty)
          Container(
            padding: EdgeInsets.all(isLarge ? 24 : 16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Center(
              child: Text(
                'grocery.no_reviews'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 14 : 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length > 3 ? 3 : _reviews.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return _buildReviewCard(_reviews[index], isLarge, lang);
            },
          ),
      ],
    );
  }

  Widget _buildReviewCard(
      ProductReviewModel review, bool isLarge, String lang) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: isLarge ? 20 : 18.r,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: review.userPhoto != null
                    ? CachedNetworkImageProvider(review.userPhoto!)
                    : null,
                child: review.userPhoto == null
                    ? Text(
                        review.userName.isNotEmpty
                            ? review.userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),

              // Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontSize: isLarge ? 14 : 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      review.getTimeAgo(lang),
                      style: TextStyle(
                        fontSize: isLarge ? 12 : 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: isLarge ? 18 : 16.sp,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (review.isVerifiedPurchase) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: AppColors.success,
                  size: isLarge ? 16 : 14.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'grocery.verified_purchase'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 12 : 11.sp,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(bool isLarge, String lang) {
    final totalPrice = widget.product.price * _quantity;

    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: isLarge ? 56 : 52.h,
          child: ElevatedButton(
            onPressed: _isAddingToCart ? null : _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isAddingToCart
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart, size: isLarge ? 24 : 22.sp),
                      SizedBox(width: 12.w),
                      Text(
                        '${'grocery.add_to_cart'.tr()} - ${totalPrice.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                        style: TextStyle(
                          fontSize: isLarge ? 16 : 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
