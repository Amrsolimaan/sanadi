import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../viewmodel/cart_cubit.dart';
import '../viewmodel/cart_state.dart';
import '../model/cart_item_model.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isLarge),
      body: SafeArea(
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            if (state is CartLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is CartError) {
              return _buildErrorWidget(context, state.message, isLarge);
            }

            if (state is CartLoaded) {
              if (state.isEmpty) {
                return _buildEmptyCart(context, isLarge);
              }
              return _buildCartContent(context, state, isLarge, lang);
            }

            return const SizedBox.shrink();
          },
        ),
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
      title: Text(
        'grocery.cart'.tr(),
        style: TextStyle(
          fontSize: isLarge ? 20 : 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            if (state is CartLoaded && state.isNotEmpty) {
              return TextButton(
                onPressed: () => _showClearCartDialog(context),
                child: Text(
                  'grocery.clear_cart'.tr(),
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: isLarge ? 14 : 13.sp,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildCartContent(
    BuildContext context,
    CartLoaded state,
    bool isLarge,
    String lang,
  ) {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(isLarge ? 24 : 16.w),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => SizedBox(height: isLarge ? 16 : 12.h),
            itemBuilder: (context, index) {
              return _buildCartItem(
                context,
                state.items[index],
                state,
                isLarge,
                lang,
              );
            },
          ),
        ),

        // Bottom Summary
        _buildBottomSummary(context, state, isLarge, lang),
      ],
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItemModel item,
    CartLoaded state,
    bool isLarge,
    String lang,
  ) {


    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: lang == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: isLarge ? 28 : 24.sp,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(context);
      },
      onDismissed: (direction) {
        context.read<CartCubit>().removeItem(item.id);
      },
      child: Container(
        padding: EdgeInsets.all(isLarge ? 16 : 12.w),
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
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl ?? '',
                width: isLarge ? 90 : 75.w,
                height: isLarge ? 90 : 75.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.lightGrey,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.lightGrey,
                  child: Icon(Icons.image, size: 30.sp),
                ),
              ),
            ),
            SizedBox(width: isLarge ? 16 : 12.w),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    item.getName(lang),
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Unit
                  Text(
                    item.getUnitDisplay(lang),
                    style: TextStyle(
                      fontSize: isLarge ? 13 : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Price and Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.price.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                            style: TextStyle(
                              fontSize: isLarge ? 14 : 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${item.formattedTotal} ${'grocery.currency'.tr()}',
                            style: TextStyle(
                              fontSize: isLarge ? 16 : 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      // Quantity Selector
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.lightGrey),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context
                                    .read<CartCubit>()
                                    .decreaseQuantity(item.id);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: EdgeInsets.all(isLarge ? 8 : 6.w),
                                child: Icon(
                                  Icons.remove,
                                  size: isLarge ? 20 : 18.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),

                            // Quantity
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLarge ? 12 : 10.w,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: TextStyle(
                                  fontSize: isLarge ? 16 : 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),

                            // Increase
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context
                                    .read<CartCubit>()
                                    .increaseQuantity(item.id);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: EdgeInsets.all(isLarge ? 8 : 6.w),
                                child: Icon(
                                  Icons.add,
                                  size: isLarge ? 20 : 18.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildBottomSummary(
    BuildContext context,
    CartLoaded state,
    bool isLarge,
    String lang,
  ) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 24 : 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Items count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'grocery.items_count'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 15 : 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${state.totalItems}',
                  style: TextStyle(
                    fontSize: isLarge ? 15 : 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'grocery.subtotal'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 15 : 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${state.subtotal.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                  style: TextStyle(
                    fontSize: isLarge ? 15 : 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Delivery note
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isLarge ? 18 : 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'grocery.delivery_note'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 12 : 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            Divider(height: isLarge ? 24 : 20.h),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'grocery.total'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 18 : 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${state.totalAmount.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLarge ? 20 : 16.h),

            // Minimum order warning
            if (!state.meetsMinimumOrder)
              Container(
                padding: EdgeInsets.all(isLarge ? 12 : 10.w),
                margin: EdgeInsets.only(bottom: isLarge ? 16 : 12.h),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppColors.warning,
                      size: isLarge ? 22 : 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'grocery.minimum_order_warning'.tr(),
                        style: TextStyle(
                          fontSize: isLarge ? 13 : 12.sp,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              height: isLarge ? 56 : 52.h,
              child: ElevatedButton(
                onPressed: state.meetsMinimumOrder
                    ? () => context.pushFadeSlide(
                          CheckoutScreen(
                            items: state.items,
                            subtotal: state.subtotal,
                            total: state.totalAmount,
                          ),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.textHint,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'grocery.proceed_checkout'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 16 : 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isLarge) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 48 : 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: isLarge ? 100 : 80.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 24.h),
            Text(
              'grocery.empty_cart'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 20 : 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'grocery.empty_cart_message'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 15 : 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isLarge ? 48 : 40.w,
                  vertical: isLarge ? 16 : 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'grocery.start_shopping'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 16 : 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
            onPressed: () => context.read<CartCubit>().loadCart(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('grocery.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('grocery.remove_item'.tr()),
            content: Text('grocery.remove_item_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('grocery.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'grocery.remove'.tr(),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('grocery.clear_cart'.tr()),
        content: Text('grocery.clear_cart_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('grocery.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<CartCubit>().clearCart();
              Navigator.pop(context);
            },
            child: Text(
              'grocery.clear'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
