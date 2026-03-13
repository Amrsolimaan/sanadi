import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import 'add_category_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '📋 إدارة التصنيفات',
          style: TextStyle(
            fontSize: isLarge ? 20 : 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.white),
            onPressed: () async {
              final result = await context.pushFadeSlide(const AddCategoryScreen());
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('grocery_categories')
              .orderBy('order')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64.sp, color: AppColors.error),
                    SizedBox(height: 16.h),
                    Text('خطأ: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final categories = snapshot.data?.docs ?? [];

            if (categories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 80.sp, color: AppColors.textHint),
                    SizedBox(height: 16.h),
                    Text(
                      'لا توجد تصنيفات',
                      style: TextStyle(
                        fontSize: isLarge ? 18 : 16.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton.icon(
                      onPressed: () => context.pushFadeSlide(const AddCategoryScreen()),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة تصنيف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(isLarge ? 24 : 16.w),
              itemCount: categories.length,
              separatorBuilder: (_, __) => SizedBox(height: isLarge ? 12 : 10.h),
              itemBuilder: (context, index) {
                final doc = categories[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildCategoryCard(doc.id, data, isLarge);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String id, Map<String, dynamic> data, bool isLarge) {
    final color = _parseColor(data['color'] ?? '0xFF4CAF50');
    final isActive = data['isActive'] ?? true;

    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : AppColors.lightGrey,
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
          // Color indicator
          Container(
            width: 4.w,
            height: isLarge ? 60 : 50.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: isLarge ? 16 : 12.w),

          // Image
          Container(
            width: isLarge ? 56 : 48.w,
            height: isLarge ? 56 : 48.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: _getCategoryImageUrl(data['image'] ?? ''),
                fit: BoxFit.cover,
                placeholder: (_, __) => Icon(
                  Icons.category,
                  color: color,
                  size: isLarge ? 28 : 24.sp,
                ),
                errorWidget: (_, __, ___) => Icon(
                  Icons.category,
                  color: color,
                  size: isLarge ? 28 : 24.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: isLarge ? 16 : 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data['nameAr'] ?? '',
                        style: TextStyle(
                          fontSize: isLarge ? 16 : 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'مفعّل' : 'معطّل',
                        style: TextStyle(
                          fontSize: isLarge ? 10 : 9.sp,
                          color: isActive ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  data['nameEn'] ?? '',
                  style: TextStyle(
                    fontSize: isLarge ? 13 : 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ID: $id  |  الترتيب: ${data['order'] ?? 0}',
                  style: TextStyle(
                    fontSize: isLarge ? 11 : 10.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              // Toggle Active
              IconButton(
                icon: Icon(
                  isActive ? Icons.visibility : Icons.visibility_off,
                  color: isActive ? AppColors.success : AppColors.textHint,
                  size: isLarge ? 22 : 20.sp,
                ),
                onPressed: () => _toggleActive(id, isActive),
              ),
              // Delete
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: isLarge ? 22 : 20.sp,
                ),
                onPressed: () => _confirmDelete(id, data['nameAr']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCategoryImageUrl(String imageName) {
    if (imageName.isEmpty) return '';
    const supabaseUrl = 'https://pljrxqzinvdcyxffablj.supabase.co';
    return '$supabaseUrl/storage/v1/object/public/images/grocery/categories/$imageName';
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('0x', ''), radix: 16));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  Future<void> _toggleActive(String id, bool currentState) async {
    try {
      await FirebaseFirestore.instance
          .collection('grocery_categories')
          .doc(id)
          .update({'isActive': !currentState});

      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentState ? 'تم تعطيل التصنيف' : 'تم تفعيل التصنيف'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف تصنيف "$name"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategory(id);
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('grocery_categories')
          .doc(id)
          .delete();

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف التصنيف'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
