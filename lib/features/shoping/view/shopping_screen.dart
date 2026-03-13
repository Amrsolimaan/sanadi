import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/core/utils/page_transitions.dart';
import 'package:sanadi/core/widgets/app_bottom_nav.dart';
import 'package:sanadi/features/grocery/view/grocery_categories_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../viewmodel/shopping_cubit.dart';
import '../viewmodel/shopping_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore/grocery_service.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import '../../grocery/model/grocery_order_model.dart';
import '../../grocery/view/reorder_dialog.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocProvider(
      create: (context) => ShoppingCubit(),
      child: BlocBuilder<ShoppingCubit, ShoppingState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'shopping.title'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 20 : 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isLarge ? 32 : 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Text(
                      'shopping.shop_by_category'.tr(),
                      style: TextStyle(
                        fontSize: isLarge ? 22 : 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: isLarge ? 24 : 16.h),

                    // Category Cards
                    if (state is ShoppingLoaded)
                      ...state.categories.map((category) => Padding(
                            padding:
                                EdgeInsets.only(bottom: isLarge ? 20 : 16.h),
                            child: _buildCategoryCard(
                              context: context,
                              icon: ShoppingCubit.getIconFromName(
                                  category.iconName),
                              iconColor: Color(category.colorValue),
                              title: category.titleKey.tr(),
                              description: category.descriptionKey.tr(),
                              buttonText: category.buttonTextKey.tr(),
                              buttonColor: Color(category.colorValue),
                              onTap: () =>
                                  _navigateToCategory(context, category.id),
                              isLarge: isLarge,
                            ),
                          ))
                    else if (state is ShoppingLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ..._buildDefaultCategories(context, isLarge),

                    SizedBox(height: isLarge ? 16 : 8.h),

                    // Quick Order Section
                    Text(
                      'shopping.quick_order'.tr(),
                      style: TextStyle(
                        fontSize: isLarge ? 22 : 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: isLarge ? 16 : 12.h),

                    _buildQuickOrderCard(context, isLarge),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: const AppBottomNav(currentIndex: 1),
          );
        },
      ),
    );
  }

  // Default Categories (fallback)
  List<Widget> _buildDefaultCategories(BuildContext context, bool isLarge) {
    return [
      _buildCategoryCard(
        context: context,
        icon: Icons.shopping_basket,
        iconColor: AppColors.secondary,
        title: 'shopping.groceries'.tr(),
        description: 'shopping.groceries_desc'.tr(),
        buttonText: 'shopping.shop_groceries'.tr(),
        buttonColor: AppColors.secondary,
        onTap: () => _navigateToCategory(context, 'groceries'),
        isLarge: isLarge,
      ),
      SizedBox(height: isLarge ? 20 : 16.h),
      _buildCategoryCard(
        context: context,
        icon: Icons.local_pharmacy,
        iconColor: AppColors.primary,
        title: 'shopping.pharmacy'.tr(),
        description: 'shopping.pharmacy_desc'.tr(),
        buttonText: 'shopping.shop_pharmacy'.tr(),
        buttonColor: AppColors.logoOrange,
        onTap: () => _navigateToCategory(context, 'pharmacy'),
        isLarge: isLarge,
      ),
      SizedBox(height: isLarge ? 20 : 16.h),
      _buildCategoryCard(
        context: context,
        icon: Icons.home_outlined,
        iconColor: AppColors.primary,
        title: 'shopping.household'.tr(),
        description: 'shopping.household_desc'.tr(),
        buttonText: 'shopping.shop_household'.tr(),
        buttonColor: AppColors.primary,
        onTap: () => _navigateToCategory(context, 'household'),
        isLarge: isLarge,
      ),
      SizedBox(height: isLarge ? 20 : 16.h),
      _buildCategoryCard(
        context: context,
        icon: Icons.spa_outlined,
        iconColor: const Color(0xFF9C27B0),
        title: 'shopping.personal_care'.tr(),
        description: 'shopping.personal_care_desc'.tr(),
        buttonText: 'shopping.shop_personal_care'.tr(),
        buttonColor: const Color(0xFF9C27B0),
        onTap: () => _navigateToCategory(context, 'personal_care'),
        isLarge: isLarge,
      ),
    ];
  }

  void _navigateToCategory(BuildContext context, String categoryId) {
    if (categoryId == 'groceries' || categoryId == 'GroceryCategoriesScreen') {
      context.pushSlideRight(const GroceryCategoriesScreen());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('shopping.coming_soon_section'.tr()),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  // Category Card Widget
  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
    required bool isLarge,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 28 : 20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Circle
          Container(
            width: isLarge ? 72 : 60.w,
            height: isLarge ? 72 : 60.h,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: isLarge ? 36 : 30.sp,
              color: iconColor,
            ),
          ),
          SizedBox(height: isLarge ? 16 : 12.h),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: isLarge ? 18 : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isLarge ? 8 : 6.h),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isLarge ? 14 : 13.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: isLarge ? 16 : 12.h),

          // Button
          SizedBox(
            width: double.infinity,
            height: isLarge ? 48 : 44.h,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: isLarge ? 15 : 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Order Card
  Widget _buildQuickOrderCard(BuildContext context, bool isLarge) {
    return GestureDetector(
      onTap: () {
        // Create dummy items for demonstration
        final dummyItems = [
          OrderItemModel(
            productId: 'demo_123',
            nameAr: 'طماطم',
            nameEn: 'Tomatoes',
            price: 15.0,
            quantity: 2,
            unit: 'kg',
            imageUrl: '',
            total: 30.0,
          ),
          OrderItemModel(
            productId: 'demo_456',
            nameAr: 'خيار',
            nameEn: 'Cucumber',
            price: 12.0,
            quantity: 1,
            unit: 'kg',
            imageUrl: '',
            total: 12.0,
          ),
        ];

        showDialog(
          context: context,
          builder: (context) => ReorderDialog(
            items: dummyItems,
            lang: context.locale.languageCode,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isLarge ? 24 : 20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: isLarge ? 56 : 48.w,
              height: isLarge ? 56 : 48.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flash_on,
                size: isLarge ? 28 : 24.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: isLarge ? 16 : 12.w),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'shopping.quick_order_title'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'shopping.quick_order_desc'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 13 : 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              width: isLarge ? 40 : 36.w,
              height: isLarge ? 40 : 36.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward,
                color: AppColors.white,
                size: isLarge ? 20 : 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('grocery.products'.tr()),
        centerTitle: true,
      ),
      body: Center(
        child: Text('shopping.coming_soon_section'.tr()),
      ),
    );
  }
}
