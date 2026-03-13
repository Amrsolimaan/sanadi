import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/language_cubit.dart';
import '../tabs/grocery_management_tab.dart';
import '../tabs/medical_management_tab.dart';
import '../tabs/users_management_tab.dart';
import '../tabs/analytics_management_tab.dart'; // ✅ Import
import '../tabs/settings_tab.dart';
import '../viewmodel/admin_cubit.dart';
import '../viewmodel/admin_state.dart';
import '../../profile/viewmodel/profile_cubit.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  // ✅ قائمة التابات
  final List<Widget> _tabWidgets = const [
    GroceryManagementTab(),
    MedicalManagementTab(),
    UsersManagementTab(),
    AnalyticsManagementTab(), // ✅ New Tab
    SettingsTab(),
  ];

  final List<IconData> _tabIcons = const [
    Icons.shopping_cart,
    Icons.local_hospital,
    Icons.people,
    Icons.analytics, // ✅ New Icon
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadAdminData();
  }

  void _loadAdminData() {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      context.read<AdminCubit>().loadDashboard(profileState.user);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ✅ الحصول على عنوان التاب بالترجمة
  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'admin.grocery_management'.tr();
      case 1:
        return 'admin.medical_management'.tr();
      case 2:
        return 'admin.users_management'.tr();
      case 3:
        return 'admin.settings'.tr();
      default:
        return '';
    }
  }

  // ✅ الحصول على اسم التاب القصير للـ bottom nav
  String _getTabLabel(int index) {
    switch (index) {
      case 0:
        return 'admin.tab_grocery'.tr();
      case 1:
        return 'admin.tab_medical'.tr();
      case 2:
        return 'admin.tab_users'.tr();
      case 3:
        return 'admin.tab_settings'.tr();
      default:
        return '';
    }
  }

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    // For Users tab, we can call the Cubit directly
    if (_currentIndex == 2) {
      context.read<AdminCubit>().searchUsers(value);
    }
  }

  // ... (existing methods)

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    // Rebuild tabs when search query changes
    final List<Widget> currentTabs = [
      GroceryManagementTab(searchQuery: _searchQuery),
      MedicalManagementTab(searchQuery: _searchQuery),
      UsersManagementTab(), // Users tab handles search via Cubit
      const AnalyticsManagementTab(),
      const SettingsTab(),
    ];

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocBuilder<AdminCubit, AdminState>(
          builder: (context, state) {
            String adminName = 'Admin';
            String adminRole = '';

            if (state is AdminLoaded) {
              adminName = state.currentAdmin.fullName;
              adminRole = state.currentAdmin.role.name;
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.primary,
                elevation: 0,
                title: _currentIndex == 3 || _currentIndex == 4 // No search for Analytics/Settings
                    ? Text(
                        _getTabTitle(_currentIndex),
                        style: TextStyle(
                            fontSize: isLarge ? 18 : 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white),
                      )
                    : Container(
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: const Icon(Icons.search, color: Colors.white),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                          ),
                        ),
                      ),
                // ... actions
                actions: [
                  // Notification Icon
                  IconButton(
                    icon: Stack(
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: AppColors.white, size: isLarge ? 24 : 22.sp),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  // Profile Icon
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: CircleAvatar(
                      backgroundColor: AppColors.white.withOpacity(0.2),
                      child: Icon(Icons.person,
                          color: AppColors.white, size: isLarge ? 20 : 18.sp),
                    ),
                  ),
                ],
              ),
              body: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: currentTabs,
              ),
              bottomNavigationBar: _buildBottomNavigationBar(isLarge),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(bool isLarge) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 40 : 8.w,
            vertical: isLarge ? 12 : 8.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _tabWidgets.length,
              (index) => _buildNavItem(
                icon: _tabIcons[index],
                index: index,
                isLarge: isLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isLarge,
  }) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: isLarge ? 12 : 10.h,
            horizontal: isLarge ? 16 : 8.w,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: isLarge ? 26 : 24.sp,
              ),
              SizedBox(height: 4.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isLarge ? 11 : 10.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                child: Text(
                  _getTabLabel(index),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
