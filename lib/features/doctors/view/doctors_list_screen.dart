import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../model/doctor_model.dart';
import '../model/specialty_model.dart';
import '../viewmodel/doctors_cubit.dart';
import '../viewmodel/doctors_state.dart';
import 'doctor_details_screen.dart';
import '../../../services/firestore/supabase_storage_service.dart';

class DoctorsListScreen extends StatefulWidget {
  final String? initialSpecialty;

  const DoctorsListScreen({super.key, this.initialSpecialty});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _isSpecialtyView = widget.initialSpecialty == null;
    _loadData();
  }

  void _loadData() {
    context.read<DoctorsCubit>().loadDoctorsList(
          specialtyFilter: widget.initialSpecialty,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    final lang = context.locale.languageCode;
    context.read<DoctorsCubit>().searchDoctors(query, lang);
  }

  bool _isSpecialtyView = true;

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;

    String title = _isSpecialtyView
        ? (lang == 'ar' ? 'التخصصات' : 'Specialties')
        : (lang == 'ar' ? 'الأطباء' : 'Doctors');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (!_isSpecialtyView && widget.initialSpecialty == null) {
              setState(() {
                _isSpecialtyView = true;
                _searchController.clear();
                context.read<DoctorsCubit>().clearSearch();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocBuilder<DoctorsCubit, DoctorsState>(
          builder: (context, state) {
            if (state is DoctorsLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is DoctorsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64.sp, color: AppColors.error),
                    SizedBox(height: 16.h),
                    Text(state.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: Text(lang == 'ar' ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is DoctorsLoaded) {
              return Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Container(
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
                      child: TextField(
                        controller: _searchController,
                        onChanged: (query) {
                          setState(() {}); // ✅ تحديث الـ UI فوراً
                          context
                              .read<DoctorsCubit>()
                              .searchDoctors(query, lang);
                        },
                        decoration: InputDecoration(
                          hintText: lang == 'ar'
                              ? 'ابحث عن طبيب أو تخصص...'
                              : 'Search doctor or specialty...',
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textHint,
                          ),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppColors.textSecondary),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                    context.read<DoctorsCubit>().clearSearch();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSpecialtyView = !_isSpecialtyView;
                          if (_isSpecialtyView) {
                            context
                                .read<DoctorsCubit>()
                                .filterBySpecialty('All');
                          } else {
                            context
                                .read<DoctorsCubit>()
                                .filterBySpecialty('All');
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isSpecialtyView
                                  ? (lang == 'ar'
                                      ? 'عرض التخصصات'
                                      : 'View Specialties')
                                  : (state.selectedSpecialty != null &&
                                          state.selectedSpecialty != 'All'
                                      ? (lang == 'ar'
                                          ? 'تصفية: ${state.specialties.firstWhere((s) => s.name['en'] == state.selectedSpecialty, orElse: () => state.specialties.first).getName(lang)}'
                                          : 'Filter: ${state.selectedSpecialty}')
                                      : (lang == 'ar'
                                          ? 'عرض جميع الأطباء'
                                          : 'All Doctors')),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Icon(
                              _isSpecialtyView
                                  ? Icons.grid_view_rounded
                                  : Icons.list_rounded,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _searchController.text.isNotEmpty
                        ? _buildUnifiedSearchResults(state, lang)
                        : (_isSpecialtyView
                            ? _buildSpecialtiesGrid(state.specialties, lang)
                            : _buildDoctorsList(state.filteredDoctors, lang)),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  // ============================================
  // Unified Search Results
  // ============================================
  Widget _buildUnifiedSearchResults(DoctorsLoaded state, String lang) {
    final hasSpecialties = state.filteredSpecialties.isNotEmpty;
    final hasDoctors = state.filteredDoctors.isNotEmpty;

    if (!hasSpecialties && !hasDoctors) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64.sp, color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text(
              lang == 'ar' ? 'لا توجد نتائج' : 'No results found',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        if (hasSpecialties) ...[
          Text(
            lang == 'ar' ? 'التخصصات' : 'Specialties',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.15,
            ),
            itemCount: state.filteredSpecialties.length,
            itemBuilder: (context, index) =>
                _buildSpecialtyCard(state.filteredSpecialties[index], lang),
          ),
          SizedBox(height: 24.h),
        ],
        if (hasDoctors) ...[
          Text(
            lang == 'ar' ? 'الأطباء' : 'Doctors',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.filteredDoctors.length,
            itemBuilder: (context, index) =>
                _buildDoctorCard(state.filteredDoctors[index], lang),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecialtiesGrid(List<SpecialtyModel> specialties, String lang) {
    final filteredSpecialties = _searchController.text.isEmpty
        ? specialties
        : specialties.where((specialty) {
            final query = _searchController.text.toLowerCase();
            return specialty.getName('en').toLowerCase().contains(query) ||
                specialty.getName('ar').toLowerCase().contains(query);
          }).toList();

    if (filteredSpecialties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined,
                size: 64.sp, color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text(
              lang == 'ar' ? 'لا توجد تخصصات' : 'No specialties found',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.15,
      ),
      itemCount: filteredSpecialties.length,
      itemBuilder: (context, index) =>
          _buildSpecialtyCard(filteredSpecialties[index], lang),
    );
  }

  Widget _buildSpecialtyCard(SpecialtyModel specialty, String lang) {
    String imageUrl = '';
    if (specialty.iconUrl != null && specialty.iconUrl!.isNotEmpty) {
      if (specialty.iconUrl!.startsWith('http')) {
        imageUrl = specialty.iconUrl!;
      } else {
        imageUrl = SupabaseStorageService.getSpecialtyImage(specialty.iconUrl!);
      }
    } else if (specialty.icon.isNotEmpty) {
      imageUrl = SupabaseStorageService.getSpecialtyImageByIcon(specialty.icon);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isSpecialtyView = false;
        });
        context.read<DoctorsCubit>().filterBySpecialty(specialty.name['en']);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ✅ الصورة تملأ كل المساحة بدون أي padding
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.primary.withOpacity(0.05),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('❌ Failed to load: $url');
                          return Container(
                            color: AppColors.primary.withOpacity(0.05),
                            child: Icon(
                              Icons.medical_services_rounded,
                              size: 50.sp,
                              color: AppColors.primary.withOpacity(0.4),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.primary.withOpacity(0.05),
                        child: Icon(
                          Icons.medical_services_rounded,
                          size: 50.sp,
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                      ),
              ),
            ),
            // ✅ الاسم في الأسفل فقط
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.primary.withOpacity(0.14),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                specialty.getName(lang),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(List<DoctorModel> doctors, String lang) {
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded,
                size: 64.sp, color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text(
              lang == 'ar' ? 'لا يوجد أطباء' : 'No doctors found',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: doctors.length,
      itemBuilder: (context, index) => _buildDoctorCard(doctors[index], lang),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor, String lang) {
    // ✅ توليد URL تلقائي لو مفيش imageUrl
    String finalImageUrl;

    if (doctor.hasImage && doctor.imageUrl != null) {
      // لو موجود في الـ database
      finalImageUrl = doctor.imageUrl!.startsWith('http')
          ? doctor.imageUrl!
          : SupabaseStorageService.getDoctorImage(doctor.imageUrl!);
    } else {
      // لو مش موجود، ولّد واحد من الاسم
      finalImageUrl =
          SupabaseStorageService.getDoctorImageByName(doctor.getName('en'));
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctor: doctor)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary.withOpacity(0.05),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: finalImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _doctorPlaceholder(),
                  errorWidget: (_, __, ___) => _doctorPlaceholder(),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.getName(lang),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      doctor.getSpecialty(lang),
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: Colors.amber, size: 18.sp),
                      SizedBox(width: 4.w),
                      Text(
                        doctor.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(${doctor.reviewsCount})',
                        style: TextStyle(
                            fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                      Spacer(),
                      Text(
                        lang == 'ar' ? 'عرض' : 'View',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4.w),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorPlaceholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.05),
      child: Icon(
        Icons.person,
        color: AppColors.primary.withOpacity(0.3),
        size: 32.sp,
      ),
    );
  }
}
