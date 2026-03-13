import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sanadi/features/grocery_admin/view/admin_dashboard_screen.dart';
import 'package:sanadi/features/health/view/emergency_level_screen.dart';
import 'package:sanadi/features/profile/view/personal_details_screen.dart';
import 'package:sanadi/features/profile/view/profile_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/supabase_storage.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import 'package:sanadi/core/widgets/app_bottom_nav.dart';
import '../../auth/viewmodel/auth_cubit.dart';
import '../../auth/viewmodel/auth_state.dart';
import '../../auth/view/login_screen.dart';
import '../../emergency/view/call_for_assistance_screen.dart';
import '../../emergency/viewmodel/emergency_contacts_cubit.dart';
import '../../services/view/services_screen.dart';
import '../../doctors/view/doctors_list_screen.dart';
import '../../doctors/view/doctor_details_screen.dart';
import '../../doctors/view/my_appointments_screen.dart';
import '../../doctors/viewmodel/doctors_cubit.dart';
import '../../doctors/viewmodel/doctors_state.dart';
import '../../doctors/model/doctor_model.dart';
import '../../medications/view/medications_screen.dart';
import '../../profile/viewmodel/profile_cubit.dart';
import '../viewmodel/home_cubit.dart';
import '../viewmodel/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _sosAnimationController;
  late Animation<double> _sosScaleAnimation;
  bool _isSearching = false;

  // ✅ key لتحديث صورة المستخدم فوراً
  Key _userImageKey = UniqueKey();

  // ✅ دالة التحقق من صلاحيات الأدمن
  bool _hasAdminAccess(BuildContext context) {
    // أولاً: حاول القراءة من ProfileCubit (الأحدث والأدق)
    final profileState = context.watch<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      return profileState.user.hasAdminAccess;
    }

    // ثانياً: fallback إلى AuthCubit عند بداية الجلسة
    final authState = context.watch<AuthCubit>().state;
    if (authState is AuthSuccess) {
      return authState.user.hasAdminAccess;
    }

    return false;
  }

  void _refreshUserImage() {
    setState(() {
      _userImageKey = UniqueKey();
    });
  }

  Future<void> _clearUserImageCache(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      await CachedNetworkImage.evictFromCache(imageUrl);
      final baseUrl = imageUrl.split('?').first;
      await CachedNetworkImage.evictFromCache(baseUrl);
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // SOS Pulse Animation
    _sosAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _sosScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _sosAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _loadInitialData() {
    final doctorsCubit = context.read<DoctorsCubit>();
    if (doctorsCubit.state is! DoctorsLoaded &&
        doctorsCubit.state is! DoctorsLoading) {
      doctorsCubit.loadHomeData();
    }
    context.read<EmergencyContactsCubit>().loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sosAnimationController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    context.read<DoctorsCubit>().searchDoctorsHome(query);
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);
    final hasAdminAccess =
        _hasAdminAccess(context); // ✅ الحصول على صلاحية الأدمن

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // ✅ تحميل البروفايل فوراً عند تسجيل الدخول
          context.read<ProfileCubit>().loadUserProfile();
        } else if (state is AuthLoggedOut) {
          // ✅ إعادة تعيين البروفايل عند تسجيل الخروج
          context.read<ProfileCubit>().reset();
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        // ✅ إضافة BlocListener للـ ProfileCubit
        child: BlocListener<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state is ProfileImageUploaded) {
              _clearUserImageCache(state.imageUrl);
              _refreshUserImage();
            }
            // ✅ عند حذف الصورة
            if (state is ProfileImageDeleted) {
              _clearUserImageCache(state.deletedImageUrl);
              _refreshUserImage();
            }
            if (state is ProfileUpdated || state is ProfileLoaded) {
              _refreshUserImage();
            }
          },
          child: BlocBuilder<LanguageCubit, LanguageState>(
            builder: (context, languageState) {
              return BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  String userName = '';
                  String? userImage;
                  if (authState is AuthSuccess) {
                    userName = authState.user.fullName;
                    userImage = authState.user.profileImage;
                  }

                  // ✅ استخدام الصورة من ProfileState إذا كانت أحدث
                  final profileState = context.watch<ProfileCubit>().state;
                  if (profileState is ProfileLoaded) {
                    userImage = profileState.user.profileImage;
                  }

                  if (isLarge) {
                    return _buildDesktopLayout(
                        context, userName, userImage, hasAdminAccess);
                  }
                  return _buildMobileLayout(
                      context, userName, userImage, hasAdminAccess);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================
  // Desktop Layout
  // ============================================
  Widget _buildDesktopLayout(BuildContext context, String userName,
      String? userImage, bool hasAdminAccess) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        // ✅ التحقق من أن الـ index لا يتجاوز عدد التابات
        final tabCount = hasAdminAccess ? 5 : 4;
        int currentIndex = homeState.currentIndex;
        if (currentIndex >= tabCount) {
          currentIndex = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<HomeCubit>().changeTab(0);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // Sidebar
              Container(
                width: 280,
                color: AppColors.primary,
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Image.asset(AppAssets.logo, height: 80),
                    const SizedBox(height: 16),
                    const Text(
                      'Sanadi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildNavItem(
                      context: context,
                      icon: Icons.home,
                      label: 'nav.home'.tr(),
                      index: 0,
                      currentIndex: homeState.currentIndex,
                      isDesktop: true,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.grid_view,
                      label: 'nav.services'.tr(),
                      index: 1,
                      currentIndex: homeState.currentIndex,
                      isDesktop: true,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.history,
                      label: 'nav.history'.tr(),
                      index: 2,
                      currentIndex: homeState.currentIndex,
                      isDesktop: true,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.person,
                      label: 'nav.profile'.tr(),
                      index: 3,
                      currentIndex: currentIndex,
                      isDesktop: true,
                    ),
                    // ✅ زر Admin - يظهر فقط للـ Admin
                    if (hasAdminAccess)
                      _buildNavItem(
                        context: context,
                        icon: Icons.admin_panel_settings,
                        label: 'nav.admin'.tr(),
                        index: 4,
                        currentIndex: currentIndex,
                        isDesktop: true,
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListTile(
                        leading:
                            const Icon(Icons.logout, color: AppColors.white),
                        title: Text(
                          'auth.logout'.tr(),
                          style: const TextStyle(color: AppColors.white),
                        ),
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.lightGrey),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.search,
                                        color: AppColors.textHint),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: _onSearch,
                                      decoration: InputDecoration(
                                        hintText: 'home.search'.tr(),
                                        hintStyle: const TextStyle(
                                            color: AppColors.textHint),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.mic,
                                        color: AppColors.textHint),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          const LanguageButton(),
                          const SizedBox(width: 16),
                          _buildSosButton(context, isDesktop: true),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildContentForTab(
                            currentIndex, userName, userImage, hasAdminAccess,
                            isDesktop: true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // Mobile Layout
  // ============================================
  Widget _buildMobileLayout(BuildContext context, String userName,
      String? userImage, bool hasAdminAccess) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        // ✅ التحقق من أن الـ index لا يتجاوز عدد التابات
        final tabCount = hasAdminAccess ? 5 : 4;
        int currentIndex = homeState.currentIndex;
        if (currentIndex >= tabCount) {
          currentIndex = 0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<HomeCubit>().changeTab(0);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildContentForTab(
                  currentIndex, userName, userImage, hasAdminAccess,
                  isDesktop: false),
            ),
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            onTap: (index) => _onNavTap(context, index),
            showAdmin: hasAdminAccess,
          ),
        );
      },
    );
  }

  // ============================================
  // Content Switcher for Tabs
  // ============================================
  Widget _buildContentForTab(
      int index, String userName, String? userImage, bool hasAdminAccess,
      {required bool isDesktop}) {
    switch (index) {
      case 0:
        return _buildHomeTab(userName, userImage, isDesktop: isDesktop);
      case 1:
        return const ServicesScreen(isTab: true);
      case 2:
        return const MyAppointmentsScreen();
      case 3:
        return const ProfileScreen(showAppBar: false);
      case 4:
        // ✅ زر Admin - يظهر فقط للـ Admin
        if (hasAdminAccess) {
          return const AdminDashboardScreen();
        }
        return _buildHomeTab(userName, userImage, isDesktop: isDesktop);
      default:
        return _buildHomeTab(userName, userImage, isDesktop: isDesktop);
    }
  }

  Widget _buildHomeTab(String userName, String? userImage,
      {required bool isDesktop}) {
    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: _buildHomeContent(context, userName, userImage, isDesktop: true),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // ✅ Top Bar with padding
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                Row(
                  children: [
                    _buildSosButton(context, isDesktop: false),
                    SizedBox(width: 12.w),
                    const LanguageButton(),
                    const Spacer(),
                    Text(
                      userName.isNotEmpty ? userName : 'home.user_name'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _buildUserAvatar(userName, userImage, isDesktop: false),
                  ],
                ),
                SizedBox(height: 24.h),
                // Search Bar
                Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Icon(Icons.mic,
                            color: AppColors.textHint, size: 20.sp),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'home.search'.tr(),
                            hintStyle: TextStyle(
                                color: AppColors.textHint, fontSize: 14.sp),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Icon(Icons.search,
                            color: AppColors.textHint, size: 20.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
          // ✅ Home Content without outer padding (handles its own padding)
          _buildHomeContent(context, userName, userImage, isDesktop: false),
        ],
      ),
    );
  }

  Widget _buildProfilePlaceholder(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person,
              size: isDesktop ? 80 : 60.sp, color: AppColors.textHint),
          SizedBox(height: isDesktop ? 16 : 12.h),
          Text(
            'Profile Screen',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // User Avatar with Initial/Image
  // ============================================
  Widget _buildUserAvatar(String userName, String? userImage,
      {required bool isDesktop}) {
    final size = isDesktop ? 56.0 : 48.0; // ✅ استخدام نفس الوحدة

    return GestureDetector(
      onTap: () {
        _navigateWithTransition(context, const PersonalDetailsScreen());
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          key: _userImageKey, // ✅ key فريد
          width: isDesktop ? size : size.w,
          height: isDesktop ? size : size.w, // ✅ استخدام .w لكليهما
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: userImage != null && userImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: userImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        _buildAvatarPlaceholder(userName, size, isDesktop),
                    errorWidget: (context, url, error) =>
                        _buildInitialAvatar(userName, size, isDesktop),
                  )
                : _buildInitialAvatar(userName, size, isDesktop),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String userName, double size, bool isDesktop) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Container(
      color: AppColors.primary, // ✅ نفس لون كارد الطبيب
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String userName, double size, bool isDesktop) {
    return Container(
      color: AppColors.lightGrey,
      child: Center(
        child: Icon(Icons.person,
            color: AppColors.textHint, size: isDesktop ? 28 : 24.sp),
      ),
    );
  }

  Color _getColorFromName(String name) {
    final colors = [
      const Color(0xFF6B5CE7), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF5722), // Orange
      const Color(0xFF2196F3), // Blue
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF9800), // Amber
      const Color(0xFF9C27B0), // Deep Purple
    ];

    if (name.isEmpty) return colors[0];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  // ============================================
  // Home Content
  // ============================================
  Widget _buildHomeContent(
      BuildContext context, String userName, String? userImage,
      {required bool isDesktop}) {
    final lang = context.locale.languageCode;
    // ✅ Padding value for consistency
    final horizontalPadding = isDesktop ? 0.0 : 24.w;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isSearching) ...[
          // Looking For Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'home.looking_for'.tr(),
                  style: TextStyle(
                    fontSize: isDesktop ? 22 : 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _navigateWithTransition(context, const ServicesScreen()),
                  child: Text(
                    'home.more'.tr(),
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 14.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 16 : 16.h),

          // Categories
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              height: isDesktop ? 100 : 100.h,
              child: Row(
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      context: context,
                      icon: Icons.medical_services,
                      label: 'home.doctors'.tr(),
                      onTap: () => _navigateWithTransition(
                          context, const DoctorsListScreen()),
                      isDesktop: isDesktop,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 12.w),
                  Expanded(
                    child: _buildServiceCard(
                      context: context,
                      icon: Icons.medication,
                      label: 'medications.my_medications'.tr(),
                      onTap: () => _navigateWithTransition(
                          context, const MedicationsScreen()),
                      isDesktop: isDesktop,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 16 : 12.w),
                  Expanded(
                    child: _buildServiceCard(
                      context: context,
                      icon: Icons.run_circle,
                      label: 'services.tests'.tr(),
                      onTap: () => _navigateWithTransition(
                          context, const EmergencyLevelScreen()),
                      isDesktop: isDesktop,
                    ),

//HeartRateMeasure
                    //          child: _buildServiceCard(
                    //   context: context,
                    //   icon: Icons.favorite,
                    //   label: 'health.heart_rate'.tr(),
                    //   onTap: () => _navigateWithTransition(
                    //       context, const HeartRateMeasureScreen()),
                    //   isDesktop: isDesktop,
                    // ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isDesktop ? 32 : 24.h),
        ],

        // Popular Doctors Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSearching ? 'Search Results' : 'home.popular'.tr(),
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (!_isSearching)
                TextButton(
                  onPressed: () => _navigateWithTransition(
                      context, const DoctorsListScreen()),
                  child: Text(
                    'home.see_all'.tr(),
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 13.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12.h),

        // ✅ Popular Doctors - ListView with internal padding (no outer padding)
        SizedBox(
          height:
              isDesktop ? 260 : 250.h, // Increased height for new card design
          child: BlocBuilder<DoctorsCubit, DoctorsState>(
            builder: (context, state) {
              if (state is DoctorsLoading) {
                return _buildShimmerLoading(isDesktop);
              }
              List<DoctorModel> doctors = [];
              if (state is DoctorsLoaded) {
                doctors =
                    _isSearching ? state.searchResults : state.popularDoctors;
              }
              if (doctors.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: isDesktop ? 48 : 40.sp,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: isDesktop ? 12 : 8.h),
                      Text(
                        _isSearching
                            ? 'No results found'
                            : 'home.no_doctors'.tr(),
                        style: TextStyle(
                          fontSize: isDesktop ? 14 : 12.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                // ✅ Internal padding - cards start with padding but can scroll to edge
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 8.h), // Added vertical padding for shadow
                itemCount: doctors.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: isDesktop ? 20 : 16.w),
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  return _buildDoctorCard(
                    context: context,
                    doctor: doctor,
                    lang: lang,
                    isDesktop: isDesktop,
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: isDesktop ? 32 : 24.h),

        if (!_isSearching) ...[
          // Browse All Doctors Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: GestureDetector(
              onTap: () =>
                  _navigateWithTransition(context, const DoctorsListScreen()),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 20 : 16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isDesktop ? 56 : 48.w,
                      height: isDesktop ? 56 : 48.w, // ✅ استخدام .w لكليهما
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        color: AppColors.white,
                        size: isDesktop ? 28 : 24.sp,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 16 : 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Browse all doctors'.tr(),
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Find specialists'.tr(),
                            style: TextStyle(
                              fontSize: isDesktop ? 12 : 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: isDesktop ? 18 : 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 24 : 20.h),
        ],
      ],
    );
  }

  // ============================================
  // Shimmer Loading
  // ============================================
  Widget _buildShimmerLoading(bool isDesktop) {
    final horizontalPadding = isDesktop ? 0.0 : 24.w;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      // ✅ Same padding as doctors list
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(width: isDesktop ? 16 : 12.w),
      itemBuilder: (context, index) {
        return Container(
          width: isDesktop ? 200 : 170.w,
          decoration: BoxDecoration(
            color: AppColors.lightGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }

  // ============================================
  // Service Card
  // ============================================
  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 12 : 10.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16), // More rounded
          border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isDesktop ? 48 : 50.w, // Slightly larger
              height: isDesktop ? 48 : 50.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: AppColors.primary, size: isDesktop ? 24 : 26.sp),
            ),
            SizedBox(height: isDesktop ? 8 : 10.h),
            Text(
              label,
              style: TextStyle(
                fontSize: isDesktop ? 12 : 12.sp,
                color: AppColors.textPrimary, // Darker text
                fontWeight: FontWeight.w600, // Bolder
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SOS Button with Pulse Animation
  // ============================================
  Widget _buildSosButton(BuildContext context, {required bool isDesktop}) {
    return AnimatedBuilder(
      animation: _sosScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _sosScaleAnimation.value,
          child: GestureDetector(
            onTap: () => _navigateWithTransition(
                context, const CallForAssistanceScreen()),
            child: Container(
              width: isDesktop ? 56 : 50.w,
              height: isDesktop ? 56 : 50.w, // ✅ استخدام .w لكليهما
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'home.call_help'.tr(),
                    style: TextStyle(
                      fontSize: isDesktop ? 8 : 8.sp,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // Doctor Card with Hero Animation
  // ============================================
  Widget _buildDoctorCard({
    required BuildContext context,
    required DoctorModel doctor,
    required String lang,
    required bool isDesktop,
  }) {
    final imageUrl =
        SupabaseStorage.getDoctorImageByName(doctor.name['en'] ?? '');

    // ✅ Larger image size
    final imageSize = isDesktop ? 80.0 : 75.0;

    return Hero(
      tag: 'doctor_${doctor.id}',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => _navigateWithTransition(
              context, DoctorDetailsScreen(doctor: doctor)),
          child: Container(
            width: isDesktop ? 220 : 180.w,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ صورة الطبيب - دائرية وكبيرة
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.1), width: 2),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: isDesktop ? imageSize : imageSize.w,
                      height: isDesktop ? imageSize : imageSize.w,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 200,
                      placeholder: (context, url) => Container(
                        width: isDesktop ? imageSize : imageSize.w,
                        height: isDesktop ? imageSize : imageSize.w,
                        color: AppColors.primary.withOpacity(0.05),
                        child: Icon(Icons.person,
                            color: AppColors.primary.withOpacity(0.3),
                            size: 32.sp),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: isDesktop ? imageSize : imageSize.w,
                        height: isDesktop ? imageSize : imageSize.w,
                        color: AppColors.primary.withOpacity(0.05),
                        child: Icon(Icons.person,
                            color: AppColors.primary.withOpacity(0.3),
                            size: 32.sp),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // اسم الطبيب
                Text(
                  doctor.getName(lang),
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 4.h),

                // ✅ التخصص
                Text(
                  doctor.getSpecialty(lang),
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                // التقييم
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16.sp),
                    SizedBox(width: 4.w),
                    Text(
                      doctor.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '(${doctor.reviewsCount})',
                      style: TextStyle(
                        fontSize: isDesktop ? 11 : 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                Spacer(),

                // زر الحجز
                SizedBox(
                  width: double.infinity,
                  height: isDesktop ? 40 : 36.h,
                  child: ElevatedButton(
                    onPressed: () => _navigateWithTransition(
                        context, DoctorDetailsScreen(doctor: doctor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'home.book'.tr(),
                      style: TextStyle(
                          fontSize: isDesktop ? 13 : 13.sp,
                          fontWeight: FontWeight.w600),
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

  // ============================================
  // Navigation with Transition
  // ============================================
  void _navigateWithTransition(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ============================================
  // Navigation
  // ============================================
  void _onNavTap(BuildContext context, int index) {
    final homeCubit = context.read<HomeCubit>();
    if (homeCubit.state.currentIndex == index) {
      return; // Already on this tab
    }
    homeCubit.changeTab(index);
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required bool isDesktop,
  }) {
    final isSelected = currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ListTile(
        leading: AnimatedScale(
          scale: isSelected ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Icon(
            icon,
            color:
                isSelected ? AppColors.white : AppColors.white.withOpacity(0.6),
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? AppColors.white : AppColors.white.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.white.withOpacity(0.1),
        onTap: () => _onNavTap(context, index),
      ),
    );
  }

  Widget _buildBottomNav(
      BuildContext context, int currentIndex, bool hasAdminAccess) {
    return Container(
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
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onNavTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        items: [
          _buildBottomNavItem(Icons.home, 'nav.home'.tr(), 0, currentIndex),
          _buildBottomNavItem(
              Icons.grid_view, 'nav.services'.tr(), 1, currentIndex),
          _buildBottomNavItem(
              Icons.history, 'nav.history'.tr(), 2, currentIndex),
          _buildBottomNavItem(
              Icons.person, 'nav.profile'.tr(), 3, currentIndex),
          // ✅ زر Admin - يظهر فقط للـ Admin
          if (hasAdminAccess)
            _buildBottomNavItem(
                Icons.admin_panel_settings, 'nav.admin'.tr(), 4, currentIndex),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
      IconData icon, String label, int index, int currentIndex) {
    final isSelected = currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: isSelected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.bounceOut,
        child: Icon(icon),
      ),
      label: label,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('auth.logout'.tr()),
        content: Text('auth.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('general.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            child: Text(
              'auth.logout'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
