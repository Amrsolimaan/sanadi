import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/features/profile/viewmodel/profile_cubit.dart';
import '../../../core/constants/app_colors.dart';

import '../viewmodel/order_cubit.dart';
import '../viewmodel/order_state.dart';
import '../model/grocery_order_model.dart';

class ReorderDialog extends StatefulWidget {
  final List<OrderItemModel> items;
  final String lang;

  const ReorderDialog({
    super.key,
    required this.items,
    required this.lang,
  });

  @override
  State<ReorderDialog> createState() => _ReorderDialogState();
}

class _ReorderDialogState extends State<ReorderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Track if we are in "Quick Order" flow to show back button when viewing details
  bool _isQuickOrderFlow = false;

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _prefillUserData();
    // Check if we started with dummy items
    _isQuickOrderFlow = widget.items.any((item) => item.productId.startsWith('demo_'));
  }

  void _prefillUserData() {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      _nameController.text = profileState.user.fullName;
      _phoneController.text = profileState.user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    // Initialize Cubit with items
    return BlocProvider(
      create: (context) {
        final cubit = ReorderCubit();
        
        if (_isQuickOrderFlow) {
          // Fetch all user orders
          final profileState = context.read<ProfileCubit>().state;
          if (profileState is ProfileLoaded) {
            cubit.loadUserOrders(profileState.user.uid);
          } else {
             cubit.initReorder(widget.items);
          }
        } else {
          // Use passed items (from history screen)
          cubit.initReorder(widget.items);
        }
        
        return cubit;
      },
      child: BlocConsumer<ReorderCubit, ReorderState>(
        listener: (context, state) {
          if (state is ReorderSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('grocery.order_placed'.tr()),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ReorderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Material(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStateContent(context, state, isLarge),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, ReorderState state, bool isLarge) {
    if (state is ReorderLoading) {
      return SizedBox(
        height: 300.h,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state is ReorderHistoryLoaded) {
      return _buildOrderHistoryList(context, state.orders, isLarge);
    }

    if (state is ReorderReady) {
      return _buildReorderForm(context, state, isLarge);
    }

    return SizedBox(height: 100.h); // Fallback
  }

  /// 1. History List View
  Widget _buildOrderHistoryList(BuildContext context, List<GroceryOrderModel> orders, bool isLarge) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 32 : 20.w, vertical: 16.h),
      constraints: BoxConstraints(maxHeight: 0.8.sh),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 32.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text(
            'grocery.history_title'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 20 : 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: orders.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final order = orders[index];
                return InkWell(
                  onTap: () {
                     context.read<ReorderCubit>().initReorder(order.items);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Date & Items
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 14.sp, color: AppColors.textPrimary),
                                  SizedBox(width: 6.w),
                                  Text(
                                    order.formattedDate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  Icon(Icons.shopping_basket_outlined, size: 14.sp, color: AppColors.textSecondary),
                                  SizedBox(width: 6.w),
                                  Text(
                                    '${order.itemsCount} ${'grocery.items'.tr()}',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Right: Price & Arrow
                        Row(
                          children: [
                            Text(
                              '${order.totalAmount.toStringAsFixed(0)} ${'grocery.currency'.tr()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(Icons.arrow_forward_ios, size: 12.sp, color: AppColors.textHint),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Reorder Form View (Existing Logic)
  Widget _buildReorderForm(BuildContext context, ReorderReady state, bool isLarge) {
    final items = state.items;
    final totalPrice = state.totalPrice;
    final isLoading = context.watch<ReorderCubit>().state is ReorderLoading; 

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 32 : 20.w, vertical: 16.h),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle + Back Button Row
            Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Container(
                    width: 32.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (_isQuickOrderFlow)
                  Positioned(
                    left: 0,
                    child: InkWell(
                      onTap: () {
                         final profileState = context.read<ProfileCubit>().state;
                         if (profileState is ProfileLoaded) {
                           context.read<ReorderCubit>().loadUserOrders(profileState.user.uid);
                         }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(4.w),
                        child: Icon(Icons.arrow_back, size: 20.sp, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // Rest of content in Expanded/Flexible ScrollView
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'grocery.reorder_product'.tr(),
                      style: TextStyle(
                        fontSize: isLarge ? 20 : 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Products List
                    if (items.isEmpty)
                      Center(child: Text('No items'))
                    else
                      ...items.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: _buildProductItem(context, item, isLarge),
                          )),

                    SizedBox(height: 16.h),


                    // Delivery Form
                    _buildDeliveryForm(isLarge),
                    SizedBox(height: isLarge ? 24 : 20.h),

                    // Total
                    _buildTotalSection(totalPrice, isLarge),
                    SizedBox(height: isLarge ? 20 : 16.h),

                    // Submit Button
                    _buildSubmitButton(context, false, isLarge),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, dynamic item, bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 12 : 10.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: isLarge ? 56 : 48.w,
              height: isLarge ? 56 : 48.h,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: AppColors.lightGrey),
              errorWidget: (context, url, error) => Container(
                color: AppColors.lightGrey,
                child: Icon(Icons.image, size: 20.sp),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Name and Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lang == 'ar' ? item.nameAr : item.nameEn,
                  style: TextStyle(
                    fontSize: isLarge ? 15 : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${item.price.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                  style: TextStyle(
                    fontSize: isLarge ? 13 : 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Actions Column (Quantity + Delete)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Quantity Row
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    _buildQtyBtn(Icons.remove, isLarge, () {
                      if (item.quantity > 1) {
                         context.read<ReorderCubit>().updateQuantity(
                            item.productId, item.quantity - 1);
                      }
                    }, enabled: item.quantity > 1),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    _buildQtyBtn(Icons.add, isLarge, () {
                       context.read<ReorderCubit>().updateQuantity(
                          item.productId, item.quantity + 1);
                    }),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(width: 8.w),
          
          // Delete
          InkWell(
            onTap: () {
               context.read<ReorderCubit>().removeItem(item.productId);
            },
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Icon(Icons.close, color: AppColors.error, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, bool isLarge, VoidCallback onTap, {bool enabled = true}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Icon(
          icon, 
          size: 16.sp, 
          color: enabled ? AppColors.textPrimary : AppColors.textHint
        ),
      ),
    );
  }

  Widget _buildDeliveryForm(bool isLarge) {
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
          Text(
            'grocery.delivery_info'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 16 : 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isLarge ? 16 : 12.h),

          // Name
          _buildTextField(
            controller: _nameController,
            label: 'grocery.full_name'.tr(),
            icon: Icons.person_outline,
            isLarge: isLarge,
            validator: (v) =>
                v?.isEmpty ?? true ? 'grocery.name_required'.tr() : null,
          ),
          SizedBox(height: isLarge ? 12 : 10.h),

          // Phone
          _buildTextField(
            controller: _phoneController,
            label: 'grocery.phone'.tr(),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isLarge: isLarge,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'grocery.phone_required'.tr();
              if (v!.length < 10) return 'grocery.phone_invalid'.tr();
              return null;
            },
          ),
          SizedBox(height: isLarge ? 12 : 10.h),

          // Address
          _buildTextField(
            controller: _addressController,
            label: 'grocery.address'.tr(),
            icon: Icons.location_on_outlined,
            maxLines: 2,
            isLarge: isLarge,
            validator: (v) =>
                v?.isEmpty ?? true ? 'grocery.address_required'.tr() : null,
          ),
          SizedBox(height: isLarge ? 12 : 10.h),

          // Notes
          _buildTextField(
            controller: _notesController,
            label: '${'grocery.notes'.tr()} (${'grocery.optional'.tr()})',
            icon: Icons.note_outlined,
            isLarge: isLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isLarge,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontSize: isLarge ? 14 : 13.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: isLarge ? 13 : 12.sp,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, size: isLarge ? 20 : 18.sp),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isLarge ? 14 : 12.w,
          vertical: isLarge ? 12 : 10.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildTotalSection(double totalPrice, bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
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
            '${totalPrice.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
            style: TextStyle(
              fontSize: isLarge ? 22 : 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
      BuildContext context, bool isLoading, bool isLarge) {
    return SizedBox(
      width: double.infinity,
      height: isLarge ? 54 : 50.h,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : () => _submitReorder(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366),
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.send, size: isLarge ? 20 : 18.sp),
        label: Text(
          isLoading ? 'grocery.processing'.tr() : 'grocery.send_whatsapp'.tr(),
          style: TextStyle(
            fontSize: isLarge ? 15 : 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _submitReorder(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final profileState = context.read<ProfileCubit>().state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('grocery.login_required'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Rely on Cubit to submit the current list of items in state
    context.read<ReorderCubit>().placeReorder(
          uid: profileState.user.uid,
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          lang: widget.lang,
        );
  }
}
