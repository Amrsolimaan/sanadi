import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import '../viewmodel/order_cubit.dart';
import '../viewmodel/order_state.dart';
import '../model/grocery_order_model.dart';
import '../model/grocery_category_model.dart';
import 'add_review_screen.dart';
import 'reorder_dialog.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<OrderHistoryCubit>().setUser(authState.user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, isLarge),
      body: SafeArea(
        child: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
          builder: (context, state) {
            if (state is OrderHistoryLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is OrderHistoryError) {
              return _buildErrorWidget(context, state.message, isLarge);
            }

            if (state is OrderHistoryLoaded) {
              if (state.purchasedItems.isEmpty) {
                return _buildEmptyState(isLarge);
              }
              return _buildContent(context, state, isLarge, lang);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
        'grocery.order_history'.tr(),
        style: TextStyle(
          fontSize: isLarge ? 20 : 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
          builder: (context, state) {
            if (state is OrderHistoryLoaded &&
                state.purchasedItems.isNotEmpty) {
              return IconButton(
                icon: Icon(
                  state.isSelectionMode ? Icons.close : Icons.checklist,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  context.read<OrderHistoryCubit>().toggleSelectionMode();
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderHistoryLoaded state,
    bool isLarge,
    String lang,
  ) {
    return Column(
      children: [
        // Category Filter
        _buildCategoryFilter(context, state, isLarge, lang),

        // Selection Actions
        if (state.isSelectionMode && state.selectedItemIds.isNotEmpty)
          _buildSelectionActions(context, state, isLarge),

        // Items List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<OrderHistoryCubit>().refresh();
            },
            child: state.filteredItems.isEmpty
                ? _buildEmptyFilterState(isLarge)
                : ListView.separated(
                    padding: EdgeInsets.all(isLarge ? 24 : 16.w),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: isLarge ? 16 : 12.h),
                    itemBuilder: (context, index) {
                      return _buildPurchasedItemCard(
                        context,
                        state,
                        state.filteredItems[index],
                        isLarge,
                        lang,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    OrderHistoryLoaded state,
    bool isLarge,
    String lang,
  ) {
    return Container(
      height: isLarge ? 56 : 50.h,
      margin: EdgeInsets.symmetric(vertical: isLarge ? 12 : 8.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
        itemCount: state.categories.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => SizedBox(width: isLarge ? 12 : 10.w),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? state.selectedCategoryId == null
              : state.selectedCategoryId == state.categories[index - 1].id;

          final category = isAll ? null : state.categories[index - 1];

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<OrderHistoryCubit>().filterByCategory(
                    isAll ? null : category!.id,
                  );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLarge ? 20 : 16.w,
                vertical: isLarge ? 12 : 10.h,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.lightGrey,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  isAll ? 'grocery.all'.tr() : category!.getName(lang),
                  style: TextStyle(
                    fontSize: isLarge ? 14 : 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionActions(
    BuildContext context,
    OrderHistoryLoaded state,
    bool isLarge,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 24 : 16.w,
        vertical: isLarge ? 12 : 10.h,
      ),
      color: AppColors.error.withOpacity(0.1),
      child: Row(
        children: [
          Text(
            '${'grocery.selected'.tr()}: ${state.selectedItemIds.length}',
            style: TextStyle(
              fontSize: isLarge ? 14 : 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              context.read<OrderHistoryCubit>().selectAll();
            },
            icon: Icon(Icons.select_all, size: isLarge ? 20 : 18.sp),
            label: Text('grocery.select_all'.tr()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 8.w),
          TextButton.icon(
            onPressed: () => _showDeleteSelectedDialog(context),
            icon: Icon(Icons.delete_outline, size: isLarge ? 20 : 18.sp),
            label: Text('grocery.delete'.tr()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedItemCard(
    BuildContext context,
    OrderHistoryLoaded state,
    OrderItemModel item,
    bool isLarge,
    String lang,
  ) {
    final isSelected = state.selectedItemIds.contains(item.productId);

    return GestureDetector(
      onTap: state.isSelectionMode
          ? () {
              context
                  .read<OrderHistoryCubit>()
                  .toggleItemSelection(item.productId);
            }
          : null,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 16 : 12.w),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.error.withOpacity(0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.lightGrey,
            width: isSelected ? 1.5 : 1,
          ),
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
            // Checkbox (in selection mode)
            if (state.isSelectionMode)
              Container(
                margin: EdgeInsets.only(right: isLarge ? 12 : 10.w),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    context
                        .read<OrderHistoryCubit>()
                        .toggleItemSelection(item.productId);
                  },
                  activeColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: isLarge ? 80 : 70.w,
                height: isLarge ? 80 : 70.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.lightGrey,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.lightGrey,
                  child: Icon(Icons.image, size: 30.sp),
                ),
              ),
            ),
            SizedBox(width: isLarge ? 16 : 12.w),

            // Details
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // Quantity and Price
                  Text(
                    '${item.quantity} ${item.unit} × ${item.price.toStringAsFixed(2)} = ${item.total.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                    style: TextStyle(
                      fontSize: isLarge ? 13 : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Action Buttons
                  if (!state.isSelectionMode)
                    Row(
                      children: [
                        // Review Button
                        if (!item.isReviewed)
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.star_outline,
                              label: 'grocery.rate'.tr(),
                              color: AppColors.warning,
                              isLarge: isLarge,
                              onTap: () {
                                context.pushFadeSlide(
                                  AddReviewScreen(
                                    productId: item.productId,
                                    productName: item.getName(lang),
                                    productImage: item.imageUrl,
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: Row(
                              children: [
                                ...List.generate(5, (i) {
                                  return Icon(
                                    Icons.star,
                                    size: isLarge ? 16 : 14.sp,
                                    color: AppColors.warning,
                                  );
                                }),
                                SizedBox(width: 4.w),
                                Text(
                                  'grocery.rated'.tr(),
                                  style: TextStyle(
                                    fontSize: isLarge ? 11 : 10.sp,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(width: 8.w),

                        // Reorder Button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.refresh,
                            label: 'grocery.reorder'.tr(),
                            color: AppColors.primary,
                            isLarge: isLarge,
                            onTap: () =>
                                _showReorderDialog(context, item, lang),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLarge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 12 : 10.w,
          vertical: isLarge ? 8 : 6.h,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isLarge ? 18 : 16.sp, color: color),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 12 : 11.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReorderDialog(
      BuildContext context, OrderItemModel item, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReorderDialog(
        items: [item],
        lang: lang,
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('grocery.delete_selected'.tr()),
        content: Text('grocery.delete_selected_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('grocery.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<OrderHistoryCubit>().deleteSelectedItems();
              Navigator.pop(context);
            },
            child: Text(
              'grocery.delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLarge) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 48 : 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: isLarge ? 100 : 80.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 24.h),
            Text(
              'grocery.no_orders'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 20 : 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'grocery.no_orders_message'.tr(),
              style: TextStyle(
                fontSize: isLarge ? 15 : 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(bool isLarge) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: isLarge ? 64 : 56.sp,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16.h),
          Text(
            'grocery.no_items_in_category'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 16 : 14.sp,
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
            onPressed: () => context.read<OrderHistoryCubit>().refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('grocery.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) => _handleNavigation(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'nav.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view),
            label: 'nav.services'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: 'nav.history'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'nav.profile'.tr(),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case 1:
        Navigator.pop(context);
        break;
      case 2:
        // Already on History
        break;
      case 3:
        // Navigate to Profile
        break;
    }
  }
}
