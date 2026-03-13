import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_colors.dart';
import '../../features/home/viewmodel/home_cubit.dart';
import '../../features/profile/viewmodel/profile_cubit.dart';
import '../../features/auth/viewmodel/auth_cubit.dart';
import '../../features/auth/viewmodel/auth_state.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final bool? showAdmin;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.showAdmin,
  });

  bool _hasAdminAccess(BuildContext context) {
    if (showAdmin != null) return showAdmin!;

    // Check ProfileCubit
    final profileCubit = context.read<ProfileCubit>();
    if (profileCubit.state is ProfileLoaded) {
      return (profileCubit.state as ProfileLoaded).user.hasAdminAccess;
    }

    // Fallback to AuthCubit
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is AuthSuccess) {
      return (authCubit.state as AuthSuccess).user.hasAdminAccess;
    }

    return false;
  }

  static void handleNavigation(BuildContext context, int index) {
    final homeCubit = context.read<HomeCubit>();
    if (homeCubit.state.currentIndex == index) {
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      return;
    }

    homeCubit.changeTab(index);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final bool admin = _hasAdminAccess(context);

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
        currentIndex: currentIndex > (admin ? 4 : 3) ? 0 : currentIndex,
        onTap: onTap ?? (index) => handleNavigation(context, index),
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
          if (admin)
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
}
