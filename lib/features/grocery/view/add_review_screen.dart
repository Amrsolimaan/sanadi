import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/services/firestore/grocery_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/viewmodel/profile_cubit.dart';

class AddReviewScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productImage;
  final String? orderId;

  const AddReviewScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.productImage,
    this.orderId,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isLarge),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isLarge ? 32 : 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Info
              _buildProductInfo(isLarge),
              SizedBox(height: isLarge ? 40 : 32.h),

              // Rating Section
              _buildRatingSection(isLarge),
              SizedBox(height: isLarge ? 32 : 24.h),

              // Comment Section
              _buildCommentSection(isLarge),
              SizedBox(height: isLarge ? 40 : 32.h),

              // Submit Button
              _buildSubmitButton(isLarge),
            ],
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
        icon: const Icon(Icons.close, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'grocery.add_review'.tr(),
        style: TextStyle(
          fontSize: isLarge ? 20 : 18.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProductInfo(bool isLarge) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16.w),
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
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.productImage,
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

          // Product Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'grocery.rate_product'.tr(),
                  style: TextStyle(
                    fontSize: isLarge ? 13 : 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.productName,
                  style: TextStyle(
                    fontSize: isLarge ? 18 : 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(bool isLarge) {
    return Container(
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
      child: Column(
        children: [
          Text(
            'grocery.how_was_product'.tr(),
            style: TextStyle(
              fontSize: isLarge ? 18 : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isLarge ? 20 : 16.h),

          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _rating = index + 1);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isLarge ? 8 : 6.w),
                  child: AnimatedScale(
                    scale: _rating > index ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      _rating > index ? Icons.star : Icons.star_border,
                      size: isLarge ? 48 : 42.sp,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: isLarge ? 16 : 12.h),

          // Rating Text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _getRatingText(),
              key: ValueKey(_rating),
              style: TextStyle(
                fontSize: isLarge ? 16 : 14.sp,
                fontWeight: FontWeight.w500,
                color:
                    _rating > 0 ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'grocery.rating_1'.tr();
      case 2:
        return 'grocery.rating_2'.tr();
      case 3:
        return 'grocery.rating_3'.tr();
      case 4:
        return 'grocery.rating_4'.tr();
      case 5:
        return 'grocery.rating_5'.tr();
      default:
        return 'grocery.tap_to_rate'.tr();
    }
  }

  Widget _buildCommentSection(bool isLarge) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'grocery.your_comment'.tr(),
                style: TextStyle(
                  fontSize: isLarge ? 16 : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '(${'grocery.optional'.tr()})',
                style: TextStyle(
                  fontSize: isLarge ? 13 : 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'grocery.comment_hint'.tr(),
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: isLarge ? 14 : 13.sp,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: EdgeInsets.all(isLarge ? 16 : 14.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLarge) {
    return SizedBox(
      width: double.infinity,
      height: isLarge ? 56 : 52.h,
      child: ElevatedButton(
        onPressed: _rating > 0 && !_isSubmitting ? _submitReview : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: const CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: isLarge ? 22 : 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'grocery.submit_review'.tr(),
                    style: TextStyle(
                      fontSize: isLarge ? 16 : 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitReview() async {
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

    final user = profileState.user;

    setState(() => _isSubmitting = true);

    try {
      final service = GroceryService();
      final review = await service.addReview(
        productId: widget.productId,
        uid: user.uid,
        userName: user.fullName, // ✅ تم التصحيح: fullName بدلاً من displayName
        userPhoto:
            user.profileImage, // ✅ تم التصحيح: profileImage بدلاً من photoURL
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        orderId: widget.orderId,
      );

      if (review != null && mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('grocery.review_submitted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('grocery.review_error'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
