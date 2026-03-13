import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import 'add_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('grocery_categories')
          .orderBy('order')
          .get();

      setState(() {
        _categories = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'nameAr': doc['nameAr'],
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '📦 إدارة المنتجات',
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
              final result = await context.pushFadeSlide(const AddProductScreen());
              if (result == true) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter
            _buildCategoryFilter(isLarge),

            // Products List
            Expanded(
              child: _buildProductsList(isLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isLarge) {
    return Container(
      height: isLarge ? 56 : 50.h,
      margin: EdgeInsets.symmetric(vertical: isLarge ? 12 : 8.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => SizedBox(width: isLarge ? 10 : 8.w),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? _selectedCategoryId == null
              : _selectedCategoryId == _categories[index - 1]['id'];

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedCategoryId = isAll ? null : _categories[index - 1]['id'];
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isLarge ? 20 : 16.w),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF9C27B0) : AppColors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? const Color(0xFF9C27B0) : AppColors.lightGrey,
                ),
              ),
              child: Center(
                child: Text(
                  isAll ? 'الكل' : _categories[index - 1]['nameAr'],
                  style: TextStyle(
                    fontSize: isLarge ? 13 : 12.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildProductsList(bool isLarge) {
    Query query = FirebaseFirestore.instance
        .collection('grocery_products')
        .orderBy('createdAt', descending: true);

    if (_selectedCategoryId != null) {
      query = query.where('categoryId', isEqualTo: _selectedCategoryId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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

        final products = snapshot.data?.docs ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80.sp, color: AppColors.textHint),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد منتجات',
                  style: TextStyle(
                    fontSize: isLarge ? 18 : 16.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: () => context.pushFadeSlide(const AddProductScreen()),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة منتج'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isLarge ? 24 : 16.w),
          itemCount: products.length,
          separatorBuilder: (_, __) => SizedBox(height: isLarge ? 12 : 10.h),
          itemBuilder: (context, index) {
            final doc = products[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildProductCard(doc.id, data, isLarge);
          },
        );
      },
    );
  }

  Widget _buildProductCard(String id, Map<String, dynamic> data, bool isLarge) {
    final isAvailable = data['isAvailable'] ?? true;
    final hasDiscount = data['oldPrice'] != null && data['oldPrice'] > data['price'];
    final stock = data['stockQuantity'] ?? 0;

    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? AppColors.lightGrey : AppColors.error.withOpacity(0.3),
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
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'] ?? '',
                  width: isLarge ? 80 : 70.w,
                  height: isLarge ? 80 : 70.h,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.lightGrey,
                    child: Icon(Icons.image, size: 30.sp),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.lightGrey,
                    child: Icon(Icons.image, size: 30.sp),
                  ),
                ),
              ),
              if (hasDiscount)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      'خصم',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: isLarge ? 9 : 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: isLarge ? 16 : 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['nameAr'] ?? '',
                  style: TextStyle(
                    fontSize: isLarge ? 15 : 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? AppColors.textPrimary : AppColors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  data['nameEn'] ?? '',
                  style: TextStyle(
                    fontSize: isLarge ? 12 : 11.sp,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    // Price
                    Text(
                      '${(data['price'] ?? 0).toStringAsFixed(2)} ج.م',
                      style: TextStyle(
                        fontSize: isLarge ? 14 : 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (hasDiscount) ...[
                      SizedBox(width: 8.w),
                      Text(
                        '${(data['oldPrice']).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isLarge ? 11 : 10.sp,
                          color: AppColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    // Stock badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: stock > 10
                            ? AppColors.success.withOpacity(0.1)
                            : stock > 0
                                ? AppColors.warning.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'المخزون: $stock',
                        style: TextStyle(
                          fontSize: isLarge ? 10 : 9.sp,
                          color: stock > 10
                              ? AppColors.success
                              : stock > 0
                                  ? AppColors.warning
                                  : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // Unit
                    Text(
                      '${data['unitValue'] ?? 1} ${data['unit'] ?? 'kg'}',
                      style: TextStyle(
                        fontSize: isLarge ? 10 : 9.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            children: [
              // Toggle Available
              IconButton(
                icon: Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable ? AppColors.success : AppColors.error,
                  size: isLarge ? 22 : 20.sp,
                ),
                onPressed: () => _toggleAvailable(id, isAvailable),
              ),
              // Edit Stock
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: isLarge ? 22 : 20.sp,
                ),
                onPressed: () => _showEditStockDialog(id, stock, data['price']),
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

  Future<void> _toggleAvailable(String id, bool currentState) async {
    try {
      await FirebaseFirestore.instance
          .collection('grocery_products')
          .doc(id)
          .update({'isAvailable': !currentState});

      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentState ? 'تم إخفاء المنتج' : 'تم إظهار المنتج'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showEditStockDialog(String id, int currentStock, dynamic currentPrice) {
    final stockController = TextEditingController(text: '$currentStock');
    final priceController = TextEditingController(text: '${(currentPrice ?? 0).toStringAsFixed(2)}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المنتج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية المتاحة',
                prefixIcon: Icon(Icons.inventory),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'السعر',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateProduct(
                id,
                int.tryParse(stockController.text) ?? currentStock,
                double.tryParse(priceController.text) ?? currentPrice,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProduct(String id, int stock, double price) async {
    try {
      await FirebaseFirestore.instance
          .collection('grocery_products')
          .doc(id)
          .update({
        'stockQuantity': stock,
        'price': price,
        'isAvailable': stock > 0,
      });

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث المنتج'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف منتج "$name"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(id);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('grocery_products')
          .doc(id)
          .delete();

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف المنتج'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
