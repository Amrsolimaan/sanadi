import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../model/grocery_order_model.dart';

class OrderSuccessScreen extends StatefulWidget {
  final GroceryOrderModel order;

  const OrderSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final lang = context.locale.languageCode;

    return WillPopScope(
      onWillPop: () async {
        _navigateToHome(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isLarge ? 48 : 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Success Animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: isLarge ? 140 : 120.w,
                        height: isLarge ? 140 : 120.h,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: isLarge ? 100 : 85.w,
                            height: isLarge ? 100 : 85.h,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: AppColors.white,
                              size: isLarge ? 56 : 48.sp,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: isLarge ? 40 : 32.h),

                // Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'grocery.order_success'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 28 : 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 12.h),

                // Subtitle
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'grocery.order_success_message'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isLarge ? 40 : 32.h),

                // Order Details Card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildOrderDetailsCard(isLarge, lang),
                ),

                const Spacer(),

                // Return Home Button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: isLarge ? 56 : 52.h,
                    child: ElevatedButton(
                      onPressed: () => _navigateToHome(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'grocery.return_home'.tr(),
                        style: TextStyle(
                          fontSize: isLarge ? 16 : 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Continue Shopping Button
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: isLarge ? 56 : 52.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'grocery.continue_shopping'.tr(),
                        style: TextStyle(
                          fontSize: isLarge ? 16 : 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(bool isLarge, String lang) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLarge ? 24 : 20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Number
          _buildDetailRow(
            label: 'grocery.order_number'.tr(),
            value: widget.order.orderNumber,
            isLarge: isLarge,
            isPrimary: true,
          ),
          Divider(height: isLarge ? 24 : 20.h),

          // Items Count
          _buildDetailRow(
            label: 'grocery.items_count'.tr(),
            value: '${widget.order.itemsCount}',
            isLarge: isLarge,
          ),
          SizedBox(height: 12.h),

          // Total Amount
          _buildDetailRow(
            label: 'grocery.total'.tr(),
            value:
                '${widget.order.totalAmount.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
            isLarge: isLarge,
            valueColor: AppColors.primary,
            valueBold: true,
          ),
          SizedBox(height: 12.h),

          // Status
          _buildDetailRow(
            label: 'grocery.status'.tr(),
            value: widget.order.status.getDisplayName(lang),
            isLarge: isLarge,
            valueColor: AppColors.warning,
          ),
          SizedBox(height: 12.h),

          // Delivery Address
          _buildDetailRow(
            label: 'grocery.delivery_to'.tr(),
            value: widget.order.deliveryAddress,
            isLarge: isLarge,
            isMultiLine: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isLarge,
    bool isPrimary = false,
    Color? valueColor,
    bool valueBold = false,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 14 : 13.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isPrimary
                  ? (isLarge ? 18 : 16.sp)
                  : (isLarge ? 14 : 13.sp),
              fontWeight: (isPrimary || valueBold)
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
            maxLines: isMultiLine ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
