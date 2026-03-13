import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sanadi/features/profile/viewmodel/profile_cubit.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../viewmodel/order_cubit.dart';
import '../viewmodel/order_state.dart';
import '../model/cart_item_model.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> items;
  final double subtotal;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.subtotal,
    required this.total,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  void _prefillUserData() {
    // ✅ استخدام ProfileCubit بدلاً من AuthCubit
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
    final lang = context.locale.languageCode;

    return BlocProvider(
      create: (context) => OrderCubit(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(isLarge),
        body: SafeArea(
          child: BlocConsumer<OrderCubit, OrderState>(
            listener: (context, state) {
              if (state is OrderCreated) {
                context.pushSlideUp(
                  OrderSuccessScreen(order: state.order),
                );
              } else if (state is OrderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isLarge ? 24 : 16.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Delivery Information Section
                            _buildSectionTitle(
                              'grocery.delivery_info'.tr(),
                              Icons.local_shipping,
                              isLarge,
                            ),
                            SizedBox(height: isLarge ? 16 : 12.h),
                            _buildDeliveryForm(isLarge),
                            SizedBox(height: isLarge ? 32 : 24.h),

                            // Order Summary Section
                            _buildSectionTitle(
                              'grocery.order_summary'.tr(),
                              Icons.receipt_long,
                              isLarge,
                            ),
                            SizedBox(height: isLarge ? 16 : 12.h),
                            _buildOrderSummary(isLarge, lang),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Confirm Button
                  _buildBottomSection(context, state, isLarge, lang),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLarge) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'grocery.checkout'.tr(),
        style: TextStyle(
          fontSize: isLarge ? 20 : 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isLarge) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: isLarge ? 24 : 22.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: isLarge ? 18 : 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryForm(bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16.w),
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
      child: Column(
        children: [
          // Name Field
          _buildTextField(
            controller: _nameController,
            label: 'grocery.full_name'.tr(),
            hint: 'grocery.full_name_hint'.tr(),
            icon: Icons.person_outline,
            isLarge: isLarge,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'grocery.name_required'.tr();
              }
              return null;
            },
          ),
          SizedBox(height: isLarge ? 16 : 14.h),

          // Phone Field
          _buildTextField(
            controller: _phoneController,
            label: 'grocery.phone'.tr(),
            hint: 'grocery.phone_hint'.tr(),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isLarge: isLarge,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'grocery.phone_required'.tr();
              }
              if (value.length < 10) {
                return 'grocery.phone_invalid'.tr();
              }
              return null;
            },
          ),
          SizedBox(height: isLarge ? 16 : 14.h),

          // Address Field
          _buildTextField(
            controller: _addressController,
            label: 'grocery.address'.tr(),
            hint: 'grocery.address_hint'.tr(),
            icon: Icons.location_on_outlined,
            maxLines: 3,
            isLarge: isLarge,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'grocery.address_required'.tr();
              }
              return null;
            },
          ),
          SizedBox(height: isLarge ? 16 : 14.h),

          // Notes Field (Optional)
          _buildTextField(
            controller: _notesController,
            label: 'grocery.notes'.tr(),
            hint: 'grocery.notes_hint'.tr(),
            icon: Icons.note_outlined,
            maxLines: 2,
            isLarge: isLarge,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isLarge,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 14 : 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: isLarge ? 14 : 13.sp,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: isLarge ? 14 : 13.sp,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.textSecondary,
              size: isLarge ? 22 : 20.sp,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isLarge ? 16 : 14.w,
              vertical: isLarge ? 14 : 12.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(bool isLarge, String lang) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16.w),
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
      child: Column(
        children: [
          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => Divider(height: isLarge ? 20 : 16.h),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl ?? '',
                      width: isLarge ? 50 : 45.w,
                      height: isLarge ? 50 : 45.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.lightGrey,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.lightGrey,
                        child: Icon(Icons.image, size: 20.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.getName(lang),
                          style: TextStyle(
                            fontSize: isLarge ? 14 : 13.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${item.quantity} x ${item.price.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                          style: TextStyle(
                            fontSize: isLarge ? 12 : 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Total
                  Text(
                    '${item.formattedTotal} ${'grocery.currency'.tr()}',
                    style: TextStyle(
                      fontSize: isLarge ? 14 : 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),

          Divider(height: isLarge ? 24 : 20.h, thickness: 1),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'grocery.subtotal'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 14 : 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${widget.subtotal.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                style: TextStyle(
                  fontSize: isLarge ? 14 : 13.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'grocery.delivery_fee'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 14 : 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'grocery.delivery_upon_arrival'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 12 : 11.sp,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    OrderState state,
    bool isLarge,
    String lang,
  ) {
    final isLoading = state is OrderCreating;

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
                  '${widget.total.toStringAsFixed(2)} ${'grocery.currency'.tr()}',
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLarge ? 16 : 14.h),

            // WhatsApp Note
            Container(
              padding: EdgeInsets.all(isLarge ? 12 : 10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF25D366).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.message,
                    color: const Color(0xFF25D366),
                    size: isLarge ? 22 : 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'grocery.whatsapp_note'.tr(),
                      style: TextStyle(
                        fontSize: isLarge ? 12 : 11.sp,
                        color: const Color(0xFF25D366),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isLarge ? 16 : 14.h),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: isLarge ? 56 : 52.h,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _submitOrder(context, lang),
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
                    : Icon(Icons.send, size: isLarge ? 22 : 20.sp),
                label: Text(
                  isLoading
                      ? 'grocery.processing'.tr()
                      : 'grocery.confirm_order_whatsapp'.tr(),
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

  void _submitOrder(BuildContext context, String lang) {
    if (!_formKey.currentState!.validate()) return;

    // Check Firebase Auth explicitly
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('grocery.login_required'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // ✅ استخدام ProfileCubit بدلاً من AuthCubit
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

    context.read<OrderCubit>().createOrder(
          uid: profileState.user.uid,
          customerName: _nameController.text.trim(),
          customerPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          items: widget.items,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          lang: lang,
        );
  }
}
