import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/features/grocery_admin/view/add_edit_category_dialog.dart';
import 'package:sanadi/features/grocery_admin/view/add_edit_product_dialog.dart';
import 'package:sanadi/features/grocery_admin/view/screens/order_details_screen.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_cubit.dart';
import 'package:sanadi/features/grocery_admin/viewmodel/admin_state.dart';
import '../../../../core/constants/app_colors.dart';

class GroceryManagementTab extends StatefulWidget {
  final String? searchQuery;
  const GroceryManagementTab({super.key, this.searchQuery});

  @override
  State<GroceryManagementTab> createState() => _GroceryManagementTabState();
}

class _GroceryManagementTabState extends State<GroceryManagementTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  @override
  Widget build(BuildContext context) {
    // ... existing build ...
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(isLarge ? 24 : 16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            tabs: [
              Tab(text: 'admin.categories'.tr()),
              Tab(text: 'admin.products'.tr()),
              Tab(text: 'admin.grocery_orders_title'.tr()),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoriesTab(context, isLarge, lang),
              _buildProductsTab(context, isLarge, lang),
              _buildOrdersTab(context, isLarge, lang),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // Categories Tab
  // ============================================
  Widget _buildCategoriesTab(BuildContext context, bool isLarge, String lang) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final canAdd = state is AdminLoaded && state.currentAdmin.canAdd();

        return Column(
          children: [
            if (canAdd)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text('admin.add_category'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grocery_categories')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs;
                  if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
                    final query = widget.searchQuery!.toLowerCase();
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nameAr = (data['nameAr'] ?? data['name']?['ar'] ?? '').toString().toLowerCase();
                      final nameEn = (data['nameEn'] ?? data['name']?['en'] ?? '').toString().toLowerCase();
                      return nameAr.contains(query) || nameEn.contains(query);
                    }).toList();
                  }

                  if (docs.isEmpty)
                    return Center(child: Text('admin.no_data'.tr()));

                  return ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildCategoryCard(
                          context, doc.id, data, isLarge, lang, canAdd);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, String docId,
      Map<String, dynamic> data, bool isLarge, String lang, bool canEdit) {
    // قراءة الاسم - يمكن أن يكون Map أو String
    String name = '';
    if (data['name'] is Map) {
      final nameMap = data['name'] as Map<String, dynamic>;
      name = lang == 'ar'
          ? (nameMap['ar'] ?? nameMap['en'] ?? '')
          : (nameMap['en'] ?? nameMap['ar'] ?? '');
    } else {
      name = lang == 'ar'
          ? (data['nameAr'] ?? data['nameEn'] ?? data['name'] ?? '')
          : (data['nameEn'] ?? data['nameAr'] ?? data['name'] ?? '');
    }

    // بناء رابط الصورة
    String imageUrl = data['imageUrl'] ?? '';
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      // محاولة بناء الرابط من docId أو icon
      final icon = data['icon'] ?? docId;
      imageUrl =
          'https://pljrxqzinvdcyxffablj.supabase.co/storage/v1/object/public/images/grocery/categories/$icon.png';
    }

    final color = data['color'] ?? '#0095DA';
    final isActive = data['isActive'] ?? true;
    final order = data['order'] ?? 0;

    return GestureDetector(
      onTap:
          canEdit ? () => _showEditCategoryDialog(context, docId, data) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(isLarge ? 16 : 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: !isActive
              ? Border.all(color: AppColors.error.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 56.w,
                height: 56.w,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 56.w,
                  height: 56.w,
                  color: AppColors.lightGrey,
                  child: Icon(Icons.category,
                      size: 28.sp, color: AppColors.textHint),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF')))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.category,
                      size: 28.sp,
                      color: Color(int.parse(color.replaceFirst('#', '0xFF')))),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: Color(
                                  int.parse(color.replaceFirst('#', '0xFF'))),
                              shape: BoxShape.circle)),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: Text(name,
                              style: TextStyle(
                                  fontSize: isLarge ? 16 : 14.sp,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      _buildChip(
                          isActive ? 'admin.active'.tr() : 'admin.inactive'.tr(),
                          isActive ? AppColors.success : AppColors.error,
                          isLarge),
                      SizedBox(width: 8.w),
                      Text('${'admin.order'.tr()}: $order',
                          style: TextStyle(
                              fontSize: 11.sp, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            if (canEdit)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit')
                    _showEditCategoryDialog(context, docId, data);
                  if (v == 'delete')
                    _showDeleteDialog(context, 'grocery_categories', docId);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit, size: 20),
                        SizedBox(width: 8.w),
                        Text('general.edit'.tr())
                      ])),
                  PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete,
                            size: 20, color: AppColors.error),
                        SizedBox(width: 8.w),
                        Text('general.delete'.tr(),
                            style: const TextStyle(color: AppColors.error))
                      ])),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // Products Tab
  // ============================================
  Widget _buildProductsTab(BuildContext context, bool isLarge, String lang) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        final canAdd = state is AdminLoaded && state.currentAdmin.canAdd();

        return Column(
          children: [
            if (canAdd)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddProductDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text('admin.add_product'.tr()),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white),
                  ),
                ),
              ),
            SizedBox(height: 12.h),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('grocery_products')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  
                  var docs = snapshot.data!.docs;
                  if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
                    final query = widget.searchQuery!.toLowerCase();
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nameAr = (data['nameAr'] ?? '').toString().toLowerCase();
                      final nameEn = (data['nameEn'] ?? '').toString().toLowerCase();
                      return nameAr.contains(query) || nameEn.contains(query);
                    }).toList();
                  }

                  if (docs.isEmpty)
                    return Center(child: Text('admin.no_data'.tr()));

                  return ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildProductCard(
                          context, doc.id, data, isLarge, lang, canAdd);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, String docId,
      Map<String, dynamic> data, bool isLarge, String lang, bool canEdit) {
    // قراءة الاسم
    final name = lang == 'ar'
        ? (data['nameAr'] ?? data['nameEn'] ?? '')
        : (data['nameEn'] ?? data['nameAr'] ?? '');

    // قراءة الصورة - تدعم imageUrl مباشر أو images كـ List
    String imageUrl = '';
    if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      imageUrl = data['imageUrl'].toString();
    } else if (data['images'] is List && (data['images'] as List).isNotEmpty) {
      imageUrl = (data['images'] as List)[0].toString();
    }

    final price = (data['price'] ?? 0).toDouble();
    final oldPrice =
        data['oldPrice'] != null ? (data['oldPrice'] as num).toDouble() : null;
    final stock = data['stockQuantity'] ?? 0;
    final isAvailable = data['isAvailable'] ?? true;
    final unit = data['unit'] ?? '';
    final unitValue = data['unitValue'] ?? 1;

    Color stockColor = stock > 10
        ? AppColors.success
        : stock > 0
            ? AppColors.warning
            : AppColors.error;

    return GestureDetector(
        onTap:
            canEdit ? () => _showEditProductDialog(context, docId, data) : null,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(isLarge ? 16 : 12.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: !isAvailable
                ? Border.all(color: AppColors.error.withOpacity(0.3))
                : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              // صورة المنتج
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 70.w,
                      height: 70.w,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 70.w,
                        height: 70.w,
                        color: AppColors.lightGrey,
                        child: Icon(Icons.shopping_bag,
                            size: 30.sp, color: AppColors.textHint),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 70.w,
                        height: 70.w,
                        color: AppColors.lightGrey,
                        child: Icon(Icons.shopping_bag,
                            size: 30.sp, color: AppColors.textHint),
                      ),
                    ),
                  ),
                  // عرض الخصم إذا وجد
                  if (oldPrice != null && oldPrice > price)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          '-${(((oldPrice - price) / oldPrice) * 100).round()}%',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: isLarge ? 16 : 14.sp,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4.h),
                    // السعر مع الخصم
                    Row(
                      children: [
                        Text(
                            '${price.toStringAsFixed(0)} ${'grocery.currency'.tr()}',
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                        if (oldPrice != null && oldPrice > price) ...[
                          SizedBox(width: 8.w),
                          Text('${oldPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    // الوحدة والمخزون
                    Row(
                      children: [
                        if (unit.isNotEmpty) ...[
                          Text('$unitValue $unit',
                              style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary)),
                          SizedBox(width: 12.w),
                        ],
                        Icon(Icons.inventory, size: 14.sp, color: stockColor),
                        SizedBox(width: 4.w),
                        Text('$stock',
                            style:
                                TextStyle(fontSize: 12.sp, color: stockColor)),
                      ],
                    ),
                  ],
                ),
              ),
              if (canEdit)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit')
                      _showEditProductDialog(context, docId, data);
                    if (v == 'delete')
                      _showDeleteDialog(context, 'grocery_products', docId);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit, size: 20),
                          SizedBox(width: 8.w),
                          Text('general.edit'.tr())
                        ])),
                    PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(Icons.delete,
                              size: 20, color: AppColors.error),
                          SizedBox(width: 8.w),
                          Text('general.delete'.tr(),
                              style: const TextStyle(color: AppColors.error))
                        ])),
                  ],
                ),
            ],
          ),
        ));
  }

  // ============================================
  // Orders Tab
  // ============================================
  Widget _buildOrdersTab(BuildContext context, bool isLarge, String lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grocery_orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          final query = widget.searchQuery!.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id.toLowerCase();
            final customerName = (data['customerName'] ?? '').toString().toLowerCase();
            return id.contains(query) || customerName.contains(query);
          }).toList();
        }

        if (docs.isEmpty)
          return Center(child: Text('admin.no_data'.tr()));

        return ListView.builder(
          padding: EdgeInsets.all(isLarge ? 24 : 16.w),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildOrderCard(context, doc.id, data, isLarge, lang);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, String docId,
      Map<String, dynamic> data, bool isLarge, String lang) {
    final status = data['status'] ?? 'pending';
    final total = (data['total'] ?? 0).toDouble();
    final customerName = data['customerName'] ?? 'Unknown';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'preparing':
        statusColor = Colors.orange;
        break;
      case 'delivered':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  OrderDetailsScreen(orderId: docId, orderData: data))),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(isLarge ? 16 : 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.receipt_long, color: statusColor, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${docId.substring(0, 6).toUpperCase()}',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold)),
                  Text(customerName,
                      style: TextStyle(
                          fontSize: 13.sp, color: AppColors.textSecondary)),
                  if (createdAt != null)
                    Text(DateFormat('dd/MM/yyyy - hh:mm a').format(createdAt),
                        style: TextStyle(
                            fontSize: 11.sp, color: AppColors.textHint)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${total.toStringAsFixed(0)} ${'grocery.currency'.tr()}',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success)),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_getStatusText(status),
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: statusColor,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, bool isLarge) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: isLarge ? 11 : 10.sp,
              color: color,
              fontWeight: FontWeight.w500)),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'admin.status_confirmed'.tr();
      case 'preparing':
        return 'admin.status_preparing'.tr();
      case 'on_way':
        return 'admin.status_on_way'.tr();
      case 'delivered':
        return 'admin.status_delivered'.tr();
      case 'cancelled':
        return 'admin.status_cancelled'.tr();
      default:
        return 'admin.status_pending'.tr();
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddEditCategoryDialog());
  }

  void _showEditCategoryDialog(
      BuildContext context, String id, Map<String, dynamic> data) {
    showDialog(
        context: context,
        builder: (_) =>
            AddEditCategoryDialog(categoryId: id, categoryData: data));
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddEditProductDialog());
  }

  void _showEditProductDialog(
      BuildContext context, String id, Map<String, dynamic> data) {
    showDialog(
        context: context,
        builder: (_) => AddEditProductDialog(productId: id, productData: data));
  }

  void _showDeleteDialog(
      BuildContext context, String collection, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('admin.delete_confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('general.cancel'.tr())),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(docId)
                  .delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('admin.delete_success'.tr())));
            },
            child: Text('general.delete'.tr(),
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
