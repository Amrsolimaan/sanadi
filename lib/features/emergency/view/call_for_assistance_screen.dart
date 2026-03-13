import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../viewmodel/emergency_contacts_cubit.dart';
import '../viewmodel/emergency_contacts_state.dart';
import 'emergency_contacts_screen.dart';
import '../../location/view/location_status_screen.dart';

class CallForAssistanceScreen extends StatefulWidget {
  const CallForAssistanceScreen({super.key});

  @override
  State<CallForAssistanceScreen> createState() =>
      _CallForAssistanceScreenState();
}

class _CallForAssistanceScreenState extends State<CallForAssistanceScreen> {
  bool _isLongPressing = false;
  double _holdProgress = 0.0;

  @override
  void initState() {
    super.initState();
    context.read<EmergencyContactsCubit>().loadContacts();
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _startLongPress() {
    setState(() {
      _isLongPressing = true;
      _holdProgress = 0.0;
    });

    // Animate progress over 3 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!_isLongPressing) return false;

      setState(() {
        _holdProgress += 0.05 / 3; // 3 seconds total
      });

      if (_holdProgress >= 1.0) {
        _onSosActivated();
        return false;
      }
      return true;
    });
  }

  void _cancelLongPress() {
    setState(() {
      _isLongPressing = false;
      _holdProgress = 0.0;
    });
  }

  void _onSosActivated() {
    setState(() {
      _isLongPressing = false;
      _holdProgress = 0.0;
    });
    context.read<EmergencyContactsCubit>().callEmergency();
  }

  void _callPrimaryContact() {
    final cubit = context.read<EmergencyContactsCubit>();
    if (cubit.primaryContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('emergency.set_primary_first'.tr()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    cubit.callPrimaryContact();
  }

  // New: Open Location Sharing Screen
  void _openLocationSharing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationStatusScreen()),
    );
  }

  void _openEmergencyContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
    ).then((_) {
      // Reload contacts when returning
      context.read<EmergencyContactsCubit>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<EmergencyContactsCubit, EmergencyContactsState>(
          listener: (context, state) {
            if (state is EmergencyContactsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (isLarge) {
              return _buildDesktopLayout(context, state);
            }
            return _buildMobileLayout(context, state);
          },
        );
      },
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout(
      BuildContext context, EmergencyContactsState state) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Row(
        children: [
          // Left Side - Branding
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.logo, height: 120),
                  const SizedBox(height: 24),
                  const Text(
                    'Sanadi',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'emergency.help_description'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side - Content
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _buildContent(context, state, isDesktop: true),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: 24,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Positioned(
                    top: 24,
                    right: 24,
                    child: LanguageButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(
      BuildContext context, EmergencyContactsState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildContent(context, state, isDesktop: false),
        ),
      ),
    );
  }

  // Shared Content
  Widget _buildContent(BuildContext context, EmergencyContactsState state,
      {required bool isDesktop}) {
    // Get data from cubit directly
    final cubit = context.read<EmergencyContactsCubit>();
    String? primaryContactName = cubit.primaryContact?.name;
    bool hasPrimaryContact = cubit.primaryContact != null;

    // Update from state if loaded
    if (state is EmergencyContactsLoaded) {
      hasPrimaryContact = state.primaryContact != null;
      primaryContactName = state.primaryContact?.name;
    }

    return Column(
      children: [
        SizedBox(height: isDesktop ? 0 : 20.h),

        // Title
        Text(
          'emergency.call_for_assistance'.tr(),
          style: TextStyle(
            fontSize: isDesktop ? 28 : 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: isDesktop ? 60 : 40.h),

        // SOS Button
        _buildSosButton(isDesktop),

        SizedBox(height: isDesktop ? 24 : 16.h),

        // SOS Instructions
        Text(
          'emergency.hold_for_seconds'.tr(),
          style: TextStyle(
            fontSize: isDesktop ? 14 : 14.sp,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: isDesktop ? 48 : 32.h),

        // Quick Actions Title
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'emergency.quick_actions'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 18 : 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        SizedBox(height: isDesktop ? 16 : 16.h),

        // Primary Contact Button
        _buildQuickActionButton(
          icon: Icons.phone,
          iconColor: AppColors.error,
          title: 'emergency.primary_contact'.tr(),
          subtitle:
              hasPrimaryContact ? primaryContactName : 'emergency.not_set'.tr(),
          isEnabled: hasPrimaryContact,
          onTap: _callPrimaryContact,
          isDesktop: isDesktop,
        ),

        SizedBox(height: isDesktop ? 12 : 12.h),

        // Share My Location Button - NEW!
        _buildQuickActionButton(
          icon: Icons.location_on,
          iconColor: AppColors.success,
          title: 'emergency.share_location'.tr(),
          subtitle: 'emergency.share_location_subtitle'.tr(),
          isEnabled: true,
          onTap: _openLocationSharing,
          isDesktop: isDesktop,
        ),

        SizedBox(height: isDesktop ? 12 : 12.h),

        // Emergency Contacts Button
        _buildQuickActionButton(
          icon: Icons.people,
          iconColor: AppColors.primary,
          title: 'emergency.emergency_contacts'.tr(),
          subtitle: null,
          isEnabled: true,
          onTap: _openEmergencyContacts,
          isDesktop: isDesktop,
        ),

        SizedBox(height: isDesktop ? 0 : 24.h),
      ],
    );
  }

  // SOS Button Widget
  Widget _buildSosButton(bool isDesktop) {
    final size = isDesktop ? 180.0 : 160.w;

    return GestureDetector(
      onLongPressStart: (_) => _startLongPress(),
      onLongPressEnd: (_) => _cancelLongPress(),
      onLongPressCancel: _cancelLongPress,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress Ring
          if (_isLongPressing)
            SizedBox(
              width: size + 20,
              height: size + 20,
              child: CircularProgressIndicator(
                value: _holdProgress,
                strokeWidth: 6,
                backgroundColor: AppColors.lightGrey,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.error),
              ),
            ),

          // SOS Button
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLongPressing
                  ? AppColors.error.withOpacity(0.8)
                  : AppColors.error,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone,
                  color: AppColors.white,
                  size: isDesktop ? 40 : 36.sp,
                ),
                SizedBox(height: isDesktop ? 8 : 8.h),
                Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: isDesktop ? 32 : 28.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'emergency.call_for_help'.tr(),
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 12.sp,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Button Widget
  Widget _buildQuickActionButton({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String? subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isDesktop ? 16 : 16.w),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.white
              : AppColors.lightGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? AppColors.lightGrey
                : AppColors.lightGrey.withOpacity(0.3),
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: isDesktop ? 48 : 44.w,
              height: isDesktop ? 48 : 44.h,
              decoration: BoxDecoration(
                color: isEnabled
                    ? iconColor.withOpacity(0.1)
                    : AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled ? iconColor : AppColors.textHint,
                size: isDesktop ? 24 : 22.sp,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: isDesktop ? 4 : 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12.sp,
                        color: isEnabled
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isEnabled ? AppColors.textSecondary : AppColors.textHint,
              size: isDesktop ? 18 : 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
