import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui; // ✅ إضافة هذا للـ Path
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/supabase_storage.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../core/widgets/animated_widgets.dart';
import '../../../core/utils/page_transitions.dart';
import '../model/doctor_model.dart';
import '../model/review_model.dart';
import '../viewmodel/doctor_details_cubit.dart';
import '../viewmodel/doctor_details_state.dart';
import '../../../services/firestore/review_service.dart';
import 'booking_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;
  int _userRating = 0;
  ReviewModel? _userReview;
  bool _isEditingReview = false; // ✅ للتحكم في وضع التعديل

  @override
  void initState() {
    super.initState();
    context.read<DoctorDetailsCubit>().loadDoctor(widget.doctor);
    _loadReviews();
    _loadUserReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final reviews = await _reviewService.getDoctorReviews(widget.doctor.id);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadUserReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final review =
          await _reviewService.getUserReview(widget.doctor.id, user.uid);
      if (mounted && review != null) {
        setState(() {
          _userReview = review;
          _userRating = review.rating;
          _commentController.text = review.comment;
          _isEditingReview = false; // ✅ وضع القراءة فقط عند التحميل
        });
      }
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locale.languageCode == 'ar'
              ? 'يجب تسجيل الدخول أولاً'
              : 'Please login first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locale.languageCode == 'ar'
              ? 'الرجاء اختيار التقييم'
              : 'Please select rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.locale.languageCode == 'ar'
              ? 'الرجاء كتابة تعليق'
              : 'Please write a comment'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _reviewService.addReview(
      doctorId: widget.doctor.id,
      visitorId: user.uid,
      userName: user.displayName ?? 'User',
      userPhoto: user.photoURL,
      rating: _userRating,
      comment: _commentController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locale.languageCode == 'ar'
                ? 'تم إضافة التقييم بنجاح'
                : 'Review added successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        // ✅ إعادة تحميل التقييمات والدكتور
        await _loadReviews();
        await _loadUserReview();

        // ✅ تحديث بيانات الدكتور لتحديث الـ rating
        if (mounted) {
          context.read<DoctorDetailsCubit>().loadDoctorById(widget.doctor.id);
        }

        // Clear form if new review
        if (_userReview == null) {
          setState(() {
            _userRating = 0;
            _commentController.clear();
            _isEditingReview = false;
          });
        } else {
          setState(() {
            _isEditingReview = false; // ✅ العودة لوضع القراءة بعد التحديث
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locale.languageCode == 'ar'
                ? 'فشل إضافة التقييم'
                : 'Failed to add review'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ حذف المراجعة
  Future<void> _deleteReview() async {
    if (_userReview == null) return;

    final lang = context.locale.languageCode;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          lang == 'ar' ? 'حذف التقييم' : 'Delete Review',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          lang == 'ar'
              ? 'هل أنت متأكد من حذف تقييمك؟'
              : 'Are you sure you want to delete your review?',
          style: TextStyle(fontSize: 14.sp),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang == 'ar' ? 'إلغاء' : 'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              lang == 'ar' ? 'حذف' : 'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _reviewService.deleteReview(
      doctorId: widget.doctor.id,
      reviewId: _userReview!.id,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'ar'
                  ? 'تم حذف التقييم بنجاح'
                  : 'Review deleted successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Clear state
        setState(() {
          _userReview = null;
          _userRating = 0;
          _commentController.clear();
          _isEditingReview = false;
        });

        // Reload reviews and doctor
        await _loadReviews();
        if (mounted) {
          context.read<DoctorDetailsCubit>().loadDoctorById(widget.doctor.id);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'ar' ? 'فشل حذف التقييم' : 'Failed to delete review',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _openMap() async {
    if (!widget.doctor.hasLocation) return;

    final lat = widget.doctor.location!.latitude;
    final lng = widget.doctor.location!.longitude;

    // Try Google Maps first
    final googleUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Apple Maps
      final appleUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<DoctorDetailsCubit, DoctorDetailsState>(
          listener: (context, state) {
            if (state is FavoriteToggled) {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        state.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.isFavorite
                            ? 'doctor_details.added_to_favorites'.tr()
                            : 'doctor_details.removed_from_favorites'.tr(),
                      ),
                    ],
                  ),
                  backgroundColor:
                      state.isFavorite ? AppColors.error : AppColors.textHint,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.all(16.w),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            return _buildMobileLayout(context, state, lang);
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, DoctorDetailsState state, String lang) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildContent(context, state, lang),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, DoctorDetailsState state, String lang) {
    if (state is DoctorDetailsLoading) {
      return const _DoctorDetailsShimmer();
    }

    if (state is DoctorDetailsError) {
      return _buildErrorState(context, state.message);
    }

    final doctor = state is DoctorDetailsLoaded ? state.doctor : widget.doctor;
    final isFavorite = state is DoctorDetailsLoaded ? state.isFavorite : false;

    return Column(
      children: [
        _buildAppBar(context, doctor, isFavorite, lang),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<DoctorDetailsCubit>().loadDoctor(widget.doctor);
              await _loadReviews();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInWidget(child: _buildDoctorInfoCard(doctor, lang)),
                  SizedBox(height: 16.h),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _buildActionButtons(context),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 150),
                    child: _buildBiographySection(doctor, lang),
                  ),
                  SizedBox(height: 20.h),
                  if (doctor.hasLocation)
                    FadeInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: _buildMapSection(doctor, lang),
                    ),
                  SizedBox(height: 20.h),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 250),
                    child: _buildAddReviewSection(lang),
                  ),
                  SizedBox(height: 20.h),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: _buildReviewsSection(lang),
                  ),
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ),
        _buildBottomBar(context, doctor, isFavorite),
      ],
    );
  }

  Widget _buildAppBar(
      BuildContext context, DoctorModel doctor, bool isFavorite, String lang) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          TapScaleWidget(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 22.sp,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'doctor_details.title'.tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const LanguageButton(),
        ],
      ),
    );
  }

  // ✅ FIX 1: Fixed Doctor Image Display
  Widget _buildDoctorInfoCard(DoctorModel doctor, String lang) {
    // Get proper image URL from Supabase
    String? imageUrl;
    if (doctor.imageUrl != null && doctor.imageUrl!.isNotEmpty) {
      imageUrl = doctor.imageUrl;
    } else if (doctor.name['en'] != null) {
      // Try to get image by doctor name from Supabase
      imageUrl = SupabaseStorage.getDoctorImageByName(doctor.name['en']!);
    }

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'doctor_${doctor.id}',
            child: Container(
              width: 90.w,
              height: 90.h,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.lightGrey,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 40.sp,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 40.sp,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.getName(lang),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${doctor.getSpecialty(lang)} • ${doctor.getDegree(lang)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '(${doctor.reviewsCount} ${lang == 'ar' ? 'تقييم' : 'reviews'})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: doctor.isAvailable
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    doctor.isAvailable
                        ? (lang == 'ar' ? 'متاح' : 'Available')
                        : (lang == 'ar' ? 'غير متاح' : 'Unavailable'),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: doctor.isAvailable
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TapScaleWidget(
            onTap: () => context.read<DoctorDetailsCubit>().callDoctor(),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.phone,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'doctor_details.call'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: TapScaleWidget(
            onTap: () => context.read<DoctorDetailsCubit>().whatsAppDoctor(),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF25D366).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat,
                    color: const Color(0xFF25D366),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'doctor_details.whatsapp'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF25D366),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiographySection(DoctorModel doctor, String lang) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'doctor_details.biography'.tr(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              doctor.getBio(lang),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX 3: Interactive Map with "Open in Maps" button + Reset Location Button
  Widget _buildMapSection(DoctorModel doctor, String lang) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                lang == 'ar' ? 'موقع العيادة' : 'Clinic Location',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          if (doctor.getAddress(lang).isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Icon(
                    Icons.pin_drop_outlined,
                    color: AppColors.textHint,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      doctor.getAddress(lang),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Interactive Map - Simple like address_screen.dart
          Container(
            height: 200.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    doctor.location!.latitude,
                    doctor.location!.longitude,
                  ),
                  zoom: 16.0,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // ✅ إضافة Marker
                  setState(() {
                    final isArabic = context.locale.languageCode == 'ar';
                    _markers = {
                      Marker(
                        markerId: const MarkerId('doctor_location'),
                        position: LatLng(
                          doctor.location!.latitude,
                          doctor.location!.longitude,
                        ),
                        infoWindow: InfoWindow(
                          title: doctor.name[isArabic ? 'ar' : 'en'] ?? '',
                          snippet: doctor.specialty[isArabic ? 'ar' : 'en'] ?? '',
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                      ),
                    };
                  });
                },
                // ✅ إعدادات بسيطة مثل address_screen.dart تماماً
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: _markers,
                onTap: (LatLng position) {
                  // يمكن إضافة وظيفة هنا إذا لزم الأمر
                },
              ),
            ),
          ),

          // زر فتح الخريطة الخارجية
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMap,
                icon: Icon(
                  Icons.directions,
                  color: AppColors.primary,
                  size: 18.sp,
                ),
                label: Text(
                  lang == 'ar' ? 'فتح في الخرائط' : 'Open in Maps',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIX 2: Add Review Section with Edit Mode
  Widget _buildAddReviewSection(String lang) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  lang == 'ar'
                      ? 'سجل الدخول لإضافة تقييم'
                      : 'Login to add a review',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rate_review,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _userReview == null
                          ? (lang == 'ar' ? 'أضف تقييمك' : 'Add Your Review')
                          : (lang == 'ar' ? 'تقييمك' : 'Your Review'),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                // ✅ أزرار التعديل والحذف (تظهر فقط إذا كان هناك تقييم سابق)
                if (_userReview != null && !_isEditingReview)
                  Row(
                    children: [
                      // زر التعديل
                      TapScaleWidget(
                        onTap: () {
                          setState(() {
                            _isEditingReview = true;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // ✅ زر الحذف
                      TapScaleWidget(
                        onTap: _deleteReview,
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 16.h),

            // Rating Stars - قابلة للتعديل فقط في وضع التعديل
            Text(
              lang == 'ar' ? 'التقييم' : 'Rating',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: List.generate(5, (index) {
                final canEdit = _userReview == null || _isEditingReview;
                return GestureDetector(
                  onTap: canEdit
                      ? () {
                          setState(() {
                            _userRating = index + 1;
                          });
                        }
                      : null,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Icon(
                      index < _userRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 32.sp,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 16.h),

            // Comment TextField - للقراءة فقط أو للتعديل
            Text(
              lang == 'ar' ? 'تعليقك' : 'Your Comment',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _commentController,
              maxLines: 4,
              readOnly: _userReview != null &&
                  !_isEditingReview, // ✅ للقراءة فقط إذا كان هناك تقييم ولم يكن في وضع التعديل
              decoration: InputDecoration(
                hintText: lang == 'ar'
                    ? 'شارك تجربتك مع الدكتور...'
                    : 'Share your experience with the doctor...',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: (_userReview != null && !_isEditingReview)
                    ? AppColors.lightGrey
                        .withOpacity(0.3) // ✅ خلفية رمادية للقراءة فقط
                    : AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),

            // ✅ زر الإرسال/التحديث (يظهر فقط في وضع الإضافة أو التعديل)
            if (_userReview == null || _isEditingReview) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  // زر إلغاء (يظهر فقط في وضع التعديل)
                  if (_userReview != null && _isEditingReview)
                    Expanded(
                      child: TapScaleWidget(
                        onTap: () {
                          setState(() {
                            _isEditingReview = false;
                            // إعادة البيانات الأصلية
                            _userRating = _userReview!.rating;
                            _commentController.text = _userReview!.comment;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              lang == 'ar' ? 'إلغاء' : 'Cancel',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_userReview != null && _isEditingReview)
                    SizedBox(width: 12.w),
                  // زر الإرسال/التحديث
                  Expanded(
                    child: TapScaleWidget(
                      onTap: _submitReview,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _userReview == null
                                ? (lang == 'ar'
                                    ? 'إرسال التقييم'
                                    : 'Submit Review')
                                : (lang == 'ar'
                                    ? 'تحديث التقييم'
                                    : 'Update Review'),
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(String lang) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    lang == 'ar' ? 'التقييمات' : 'Reviews',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '(${_reviews.length})',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_isLoadingReviews)
            const _ReviewsShimmer()
          else if (_reviews.isEmpty)
            _buildEmptyReviews(lang)
          else
            ..._reviews.take(5).map((review) => _buildReviewCard(review, lang)),
          if (_reviews.length > 5)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    lang == 'ar'
                        ? 'عرض كل التقييمات (${_reviews.length})'
                        : 'View all reviews (${_reviews.length})',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews(String lang) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48.sp,
            color: AppColors.textHint,
          ),
          SizedBox(height: 12.h),
          Text(
            lang == 'ar' ? 'لا توجد تقييمات بعد' : 'No reviews yet',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, String lang) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: review.userPhoto != null
                    ? NetworkImage(review.userPhoto!)
                    : null,
                child: review.userPhoto == null
                    ? Text(
                        review.userName.isNotEmpty
                            ? review.userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      review.getFormattedDate(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.warning,
                    size: 16.sp,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              context.read<DoctorDetailsCubit>().loadDoctor(widget.doctor);
            },
            child: Text('general.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, DoctorModel doctor, bool isFavorite) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          TapScaleWidget(
            onTap: () => context.read<DoctorDetailsCubit>().toggleFavorite(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52.w,
              height: 52.h,
              decoration: BoxDecoration(
                color: isFavorite
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.lightGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFavorite
                      ? AppColors.error.withOpacity(0.3)
                      : AppColors.lightGrey,
                ),
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.error : AppColors.textHint,
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TapScaleWidget(
              onTap: doctor.isAvailable
                  ? () {
                      Navigator.push(
                        context,
                        AppPageTransitions.fadeSlide(
                          BookingScreen(doctor: doctor),
                        ),
                      );
                    }
                  : null,
              child: Container(
                height: 52.h,
                decoration: BoxDecoration(
                  color: doctor.isAvailable
                      ? AppColors.primary
                      : AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: doctor.isAvailable
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'doctor_details.book_appointment'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: doctor.isAvailable
                          ? AppColors.white
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Custom Painter للسهم تحت العلامة
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path() // ✅ استخدام ui.Path
      ..moveTo(size.width / 2, size.height) // النقطة السفلية
      ..lineTo(0, 0) // النقطة اليسرى العلوية
      ..lineTo(size.width, 0) // النقطة اليمنى العلوية
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DoctorDetailsShimmer extends StatelessWidget {
  const _DoctorDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 90.w,
                    height: 90.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150.w,
                          height: 18.h,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 100.w,
                          height: 14.h,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 80.w,
                          height: 24.h,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          ShimmerLoading(height: 48.h, borderRadius: 12),
          SizedBox(height: 20.h),
          ShimmerLoading(height: 100.h, borderRadius: 12),
          SizedBox(height: 20.h),
          ShimmerLoading(height: 180.h, borderRadius: 16),
        ],
      ),
    );
  }
}

class _ReviewsShimmer extends StatelessWidget {
  const _ReviewsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ShimmerWidget(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: Colors.grey[300],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 14.h,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: 60.w,
                          height: 10.h,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          height: 40.h,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
