import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sanadi/core/utils/page_transitions.dart';
import 'package:sanadi/features/shoping/view/shopping_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../medications/view/medications_screen.dart';
import '../../health/view/emergency_level_screen.dart';

class ServicesScreen extends StatefulWidget {
  final bool isTab;
  const ServicesScreen({super.key, this.isTab = false});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _selectedCategory = 'all';

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'services.title'.tr(),
          style: TextStyle(
            fontSize: isLarge ? 24 : 22.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 32 : 24.w,
            vertical: isLarge ? 24 : 16.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips
              _buildFilterChips(isLarge),

              SizedBox(height: isLarge ? 32 : 24.h),

              // Health Section
              if (_selectedCategory == 'all' ||
                  _selectedCategory == 'health') ...[
                _buildSectionHeader('services.health'.tr(), isLarge),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.medication_rounded,
                        label: 'services.medicine'.tr(),
                        color: const Color(0xFF6B5CE7),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MedicationsScreen(),
                            ),
                          );
                        },
                        isLarge: isLarge,
                      ),
                    ),
                    SizedBox(width: isLarge ? 24 : 16.w),
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.monitor_heart_rounded,
                        label: 'services.tests'.tr(),
                        color: const Color(0xFFFF5252),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmergencyLevelScreen(),
                            ),
                          );
                        },
                        isLarge: isLarge,
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: isLarge ? 40 : 32.h),

              // Grocery Section
              if (_selectedCategory == 'all' ||
                  _selectedCategory == 'shop') ...[
                _buildSectionHeader('services.grocery'.tr(), isLarge),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.shopping_basket_rounded,
                        label: 'services.shop_service'.tr(),
                        color: const Color(0xFF4CAF50),
                        onTap: () {
                          context.pushSlideRight(const ShoppingScreen());
                        },
                        isLarge: isLarge,
                      ),
                    ),
                    SizedBox(width: isLarge ? 24 : 16.w),
                    Expanded(
                      child: _buildServiceCard(
                        icon: Icons.delivery_dining_rounded,
                        label: 'services.delivery'.tr(),
                        color: const Color(0xFFFF9800),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'services.coming_soon'.tr(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        isLarge: isLarge,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isLarge) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: isLarge ? 20 : 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Filter Chips
  Widget _buildFilterChips(bool isLarge) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip(
            label: 'services.all'.tr(),
            isSelected: _selectedCategory == 'all',
            onTap: () => setState(() => _selectedCategory = 'all'),
            isLarge: isLarge,
          ),
          SizedBox(width: 12.w),
          _buildChip(
            label: 'services.health'.tr(),
            icon: Icons.favorite_rounded,
            isSelected: _selectedCategory == 'health',
            onTap: () => setState(() => _selectedCategory = 'health'),
            isLarge: isLarge,
          ),
          SizedBox(width: 12.w),
          _buildChip(
            label: 'services.shop'.tr(),
            icon: Icons.shopping_cart_rounded,
            isSelected: _selectedCategory == 'shop',
            onTap: () => setState(() => _selectedCategory = 'shop'),
            isLarge: isLarge,
          ),
        ],
      ),
    );
  }

  // Chip Widget
  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLarge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 24 : 20.w,
          vertical: isLarge ? 12 : 10.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.lightGrey.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: isLarge ? 20 : 18.sp,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
              SizedBox(width: 8.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 15 : 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Service Card
  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isLarge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isLarge ? 170 : 140.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern - Directional
            PositionedDirectional(
              end: -10,
              top: -10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isLarge ? 16 : 14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(isLarge ? 12 : 10.w),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: isLarge ? 32 : 24.sp,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'services.explore'.tr(),
                        style: TextStyle(
                          fontSize: isLarge ? 12 : 11.sp,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Use auto-mirrored icon to point AWAY from the text correctly in both languages
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14.sp,
                        color: AppColors.textSecondary,
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
}
