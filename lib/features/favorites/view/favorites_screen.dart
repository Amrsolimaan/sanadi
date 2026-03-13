import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/features/doctors/view/doctor_details_screen.dart';
import 'package:sanadi/services/firestore/favorite_service.dart';
import 'package:sanadi/services/firestore/supabase_storage_service.dart';
import 'package:sanadi/services/firestore/doctor_service.dart'; // ✅ إضافة
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/page_transitions.dart'; // ✅ إضافة
import '../../doctors/model/favorite_model.dart';
import '../../doctors/model/doctor_model.dart'; // ✅ إضافة
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  final DoctorService _doctorService = DoctorService(); // ✅ إضافة
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess) {
        final favorites = await _favoriteService.getUserFavorites(
          authState.user.uid,
        );
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'لم يتم تسجيل الدخول';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في تحميل المفضلة: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(FavoriteModel favorite) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess) {
        await _favoriteService.removeFavorite(
          authState.user.uid,
          favorite.doctorId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('favorites.removed'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          _loadFavorites();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ دالة جديدة للتنقل لصفحة تفاصيل الطبيب
  Future<void> _navigateToDoctorDetails(FavoriteModel favorite) async {
    try {
      // عرض loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // جلب بيانات الطبيب الكاملة
      final doctor = await _doctorService.getDoctorById(favorite.doctorId);

      if (mounted) {
        Navigator.pop(context); // إغلاق loading

        if (doctor != null) {
          // الانتقال لصفحة التفاصيل
          Navigator.push(
            context,
            AppPageTransitions.fadeSlide(
              DoctorDetailsScreen(doctor: doctor),
            ),
          ).then((_) {
            // إعادة تحميل المفضلة عند العودة (في حال تم إزالة الطبيب من المفضلة)
            _loadFavorites();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.locale.languageCode == 'ar'
                  ? 'لم يتم العثور على بيانات الطبيب'
                  : 'Doctor data not found'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // إغلاق loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.locale.languageCode == 'ar'
                ? 'خطأ في تحميل بيانات الطبيب: $e'
                : 'Error loading doctor data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Favorites'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: Text('general.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16.h),
            Text(
              'favorites.empty'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'favorites.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return _buildFavoriteCard(favorite);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteModel favorite) {
    // Get doctor image from Supabase
    final doctorImageUrl = SupabaseStorageService.getDoctorImageByName(
      favorite.doctorName['en'] ?? 'Dr. Unknown',
    );

    return InkWell(
      // ✅ إضافة InkWell للضغط على الكارد
      onTap: () => _navigateToDoctorDetails(favorite),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
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
            // Doctor Image
            Hero(
              // ✅ إضافة Hero للانتقال السلس
              tag: 'doctor_${favorite.doctorId}',
              child: Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: doctorImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      size: 30.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // Doctor Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.locale.languageCode == 'ar'
                        ? favorite.doctorName['ar'] ??
                            favorite.doctorName['en']!
                        : favorite.doctorName['en']!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.locale.languageCode == 'ar'
                        ? favorite.specialty['ar'] ?? favorite.specialty['en']!
                        : favorite.specialty['en']!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              onPressed: () => _showRemoveDialog(favorite),
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(FavoriteModel favorite) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('general.confirm'.tr()),
        content: Text(
          context.locale.languageCode == 'ar'
              ? 'هل تريد إزالة ${favorite.doctorName['ar']} من المفضلة؟'
              : 'Remove ${favorite.doctorName['en']} from favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeFavorite(favorite);
            },
            child: Text(
              'general.delete'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
