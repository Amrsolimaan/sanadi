import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
    final status = orderData['status'] ?? 'pending';
    final items = (orderData['items'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          '${'admin.order_details'.tr()} #${orderId.substring(0, 6).toUpperCase()}',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _updateStatus(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'confirmed', child: Text('admin.status_confirmed'.tr())),
              PopupMenuItem(value: 'preparing', child: Text('admin.status_preparing'.tr())),
              PopupMenuItem(value: 'on_way', child: Text('admin.status_on_way'.tr())),
              PopupMenuItem(value: 'delivered', child: Text('admin.status_delivered'.tr())),
              PopupMenuItem(value: 'cancelled', child: Text('admin.status_cancelled'.tr(), style: const TextStyle(color: AppColors.error))),
            ],
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            _buildStatusCard(status, createdAt, lang),
            SizedBox(height: 16.h),

            // Customer Info
            _buildSectionCard(
              title: 'admin.customer_info'.tr(),
              icon: Icons.person,
              children: [
                _buildInfoRow('admin.customer_name'.tr(), orderData['customerName'] ?? '-'),
                _buildInfoRow('admin.customer_phone'.tr(), orderData['customerPhone'] ?? '-'),
                _buildInfoRow('admin.delivery_address'.tr(), orderData['address'] ?? '-'),
                if (orderData['notes'] != null && orderData['notes'].toString().isNotEmpty)
                  _buildInfoRow('grocery.notes'.tr(), orderData['notes']),
              ],
            ),
            SizedBox(height: 16.h),

            // Order Items
            _buildSectionCard(
              title: 'admin.order_items'.tr(),
              icon: Icons.shopping_cart,
              children: [
                ...items.map((item) => _buildOrderItem(item, lang)).toList(),
                const Divider(),
                _buildTotalRow('grocery.subtotal'.tr(), orderData['subtotal'] ?? orderData['total'] ?? 0),
                _buildTotalRow('grocery.delivery_fee'.tr(), orderData['deliveryFee'] ?? 0),
                _buildTotalRow(
                  'admin.order_total'.tr(),
                  orderData['total'] ?? 0,
                  isTotal: true,
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(orderData['customerPhone']),
                    icon: const Icon(Icons.phone),
                    label: Text('emergency.call'.tr()),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(orderData['customerPhone']),
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, DateTime? createdAt, String lang) {
    Color statusColor;
    String statusText;

    switch (status) {
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'admin.status_confirmed'.tr();
        break;
      case 'preparing':
        statusColor = Colors.orange;
        statusText = 'admin.status_preparing'.tr();
        break;
      case 'on_way':
        statusColor = Colors.purple;
        statusText = 'admin.status_on_way'.tr();
        break;
      case 'delivered':
        statusColor = AppColors.success;
        statusText = 'admin.status_delivered'.tr();
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusText = 'admin.status_cancelled'.tr();
        break;
      default:
        statusColor = AppColors.warning;
        statusText = 'admin.status_pending'.tr();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == 'delivered' ? Icons.check_circle : Icons.local_shipping,
              color: AppColors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy - hh:mm a', lang).format(createdAt),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(dynamic item, String lang) {
    final name = lang == 'ar'
        ? (item['nameAr'] ?? item['nameEn'] ?? item['name'] ?? 'Unknown')
        : (item['nameEn'] ?? item['nameAr'] ?? item['name'] ?? 'Unknown');
    final quantity = item['quantity'] ?? 1;
    final price = (item['price'] ?? 0).toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'x$quantity',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          Text(
            '${(price * quantity).toStringAsFixed(0)} ${'grocery.currency'.tr()}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, dynamic value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            '${(value as num).toStringAsFixed(0)} ${'grocery.currency'.tr()}',
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('grocery_orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.save_success'.tr())),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.error'.tr()), backgroundColor: AppColors.error),
      );
    }
  }

  void _callCustomer(String? phone) {
    if (phone == null || phone.isEmpty) return;
    // url_launcher: launchUrl(Uri.parse('tel:$phone'));
  }

  void _openWhatsApp(String? phone) {
    if (phone == null || phone.isEmpty) return;
    // url_launcher: launchUrl(Uri.parse('https://wa.me/$phone'));
  }
}
