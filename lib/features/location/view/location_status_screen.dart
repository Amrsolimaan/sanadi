import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/localization/language_cubit.dart';
import '../viewmodel/location_cubit.dart';
import '../viewmodel/location_state.dart';
import '../../emergency/view/emergency_contacts_screen.dart';

class LocationStatusScreen extends StatefulWidget {
  const LocationStatusScreen({super.key});

  @override
  State<LocationStatusScreen> createState() => _LocationStatusScreenState();
}

class _LocationStatusScreenState extends State<LocationStatusScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add observer to detect when app returns from settings
    WidgetsBinding.instance.addObserver(this);
    context.read<LocationCubit>().loadLocationData();
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when app lifecycle changes (resumed, paused, etc.)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app is resumed (user returns from settings), reload data
    if (state == AppLifecycleState.resumed) {
      context.read<LocationCubit>().loadLocationData();
    }
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  void _sendToPrimary() {
    final language = context.locale.languageCode;
    context.read<LocationCubit>().sendToPrimaryContact(language);
  }

  void _shareWithAll() {
    final language = context.locale.languageCode;
    context.read<LocationCubit>().shareWithAll(language);
  }

  void _refreshLocation() {
    context.read<LocationCubit>().refreshLocation();
  }

  void _openManageContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
    ).then((_) {
      context.read<LocationCubit>().loadLocationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return BlocConsumer<LocationCubit, LocationState>(
          listener: (context, state) {
            if (state is LocationSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('location.sent_to'.tr(args: [state.contactName])),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (state is LocationSendFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is LocationError) {
              if (state.type == LocationErrorType.noPrimaryContact) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('location.no_primary_contact'.tr()),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
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
  Widget _buildDesktopLayout(BuildContext context, LocationState state) {
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
                      'location.share_description'.tr(),
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
                        constraints: const BoxConstraints(maxWidth: 450),
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
  Widget _buildMobileLayout(BuildContext context, LocationState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'location.title'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
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

  // Main Content
  Widget _buildContent(BuildContext context, LocationState state,
      {required bool isDesktop}) {
    if (state is LocationLoading) {
      return _buildLoadingState(isDesktop);
    }

    if (state is LocationError &&
        state.type != LocationErrorType.noPrimaryContact) {
      return _buildErrorState(state, isDesktop);
    }

    if (state is LocationLoaded ||
        state is LocationSending ||
        state is LocationSent) {
      return _buildLoadedState(context, state, isDesktop);
    }

    return _buildLoadingState(isDesktop);
  }

  // Loading State
  Widget _buildLoadingState(bool isDesktop) {
    return SizedBox(
      height: isDesktop ? 400 : 400.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: isDesktop ? 24 : 16.h),
            Text(
              'location.loading'.tr(),
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error State
  Widget _buildErrorState(LocationError state, bool isDesktop) {
    IconData icon;
    String buttonText;
    VoidCallback? onPressed;

    switch (state.type) {
      case LocationErrorType.serviceDisabled:
        icon = Icons.location_off;
        buttonText = 'location.open_settings';
        onPressed = () => context.read<LocationCubit>().openLocationSettings();
        break;
      case LocationErrorType.permissionDenied:
        icon = Icons.no_encryption;
        buttonText = 'location.grant_permission';
        onPressed = _refreshLocation;
        break;
      case LocationErrorType.permissionDeniedForever:
        icon = Icons.block;
        buttonText = 'location.open_app_settings';
        onPressed = () => context.read<LocationCubit>().openAppSettings();
        break;
      default:
        icon = Icons.error_outline;
        buttonText = 'location.try_again';
        onPressed = _refreshLocation;
    }

    return SizedBox(
      height: isDesktop ? 400 : 400.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isDesktop ? 80 : 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: isDesktop ? 24 : 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 20.w),
              child: Text(
                state.message.tr(),
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isDesktop ? 24 : 16.h),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 24.w,
                  vertical: isDesktop ? 12 : 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText.tr(),
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: isDesktop ? 14 : 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loaded State
  Widget _buildLoadedState(
      BuildContext context, LocationState state, bool isDesktop) {
    final cubit = context.read<LocationCubit>();
    final locationData = cubit.currentLocationData;
    final primaryContact = cubit.primaryContact;
    final isSending = state is LocationSending;

    if (locationData == null) {
      return _buildLoadingState(isDesktop);
    }

    return Column(
      children: [
        SizedBox(height: isDesktop ? 0 : 16.h),

        // Status Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isDesktop ? 24 : 20.w),
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
            children: [
              // Location Icon
              Container(
                width: isDesktop ? 80 : 70.w,
                height: isDesktop ? 80 : 70.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.white,
                  size: isDesktop ? 40 : 36.sp,
                ),
              ),

              SizedBox(height: isDesktop ? 20 : 16.h),

              // Title
              Text(
                'location.share_your_location'.tr(),
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: isDesktop ? 8 : 8.h),

              Text(
                'location.share_subtitle'.tr(),
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isDesktop ? 24 : 20.h),

              // Info Rows
              _buildInfoRow(
                icon: Icons.gps_fixed,
                label: 'location.gps_accuracy'.tr(),
                value: locationData.accuracyText,
                valueColor: _getAccuracyColor(locationData.accuracyLevel),
                isDesktop: isDesktop,
              ),

              SizedBox(height: isDesktop ? 12 : 10.h),

              _buildInfoRow(
                icon: Icons.battery_std,
                label: 'location.battery_level'.tr(),
                value: '${locationData.batteryLevel}%',
                valueColor: _getBatteryColor(locationData.batteryLevel),
                isDesktop: isDesktop,
              ),

              SizedBox(height: isDesktop ? 12 : 10.h),

              _buildInfoRow(
                icon: Icons.access_time,
                label: 'location.last_updated'.tr(),
                value: locationData.formattedTime,
                isDesktop: isDesktop,
              ),

              SizedBox(height: isDesktop ? 16 : 12.h),

              // Refresh Button
              TextButton.icon(
                onPressed: _refreshLocation,
                icon: Icon(
                  Icons.refresh,
                  size: isDesktop ? 18 : 16.sp,
                  color: AppColors.primary,
                ),
                label: Text(
                  'location.refresh'.tr(),
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 13.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isDesktop ? 24 : 20.h),

        // Primary Contact Section
        if (primaryContact != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'location.will_be_sent_to'.tr(),
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          SizedBox(height: isDesktop ? 12 : 10.h),

          // Primary Contact Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: isDesktop ? 48 : 44.w,
                  height: isDesktop ? 48 : 44.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: isDesktop ? 24 : 22.sp,
                  ),
                ),
                SizedBox(width: isDesktop ? 16 : 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            primaryContact.name,
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 8 : 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 8 : 6.w,
                              vertical: isDesktop ? 2 : 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'emergency.primary_badge'.tr(),
                              style: TextStyle(
                                fontSize: isDesktop ? 10 : 9.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (primaryContact.relationship != null) ...[
                        SizedBox(height: isDesktop ? 2 : 2.h),
                        Text(
                          primaryContact.relationship!,
                          style: TextStyle(
                            fontSize: isDesktop ? 13 : 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: isDesktop ? 24 : 22.sp,
                ),
              ],
            ),
          ),
        ],

        // No Primary Contact Warning
        if (primaryContact == null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 16 : 14.w),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: isDesktop ? 24 : 22.sp,
                ),
                SizedBox(width: isDesktop ? 12 : 10.w),
                Expanded(
                  child: Text(
                    'location.no_primary_warning'.tr(),
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 13.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: isDesktop ? 24 : 20.h),

        // Primary Button - Send to Primary Contact
// Primary Button - Send to Primary Contact via WhatsApp
        // Primary Button - Send to Primary Contact via WhatsApp
        SizedBox(
          width: double.infinity,
          height: isDesktop ? 56 : 52.h,
          child: ElevatedButton.icon(
            onPressed:
                primaryContact != null && !isSending ? _sendToPrimary : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // ✅ لون واتساب
              disabledBackgroundColor: AppColors.lightGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isSending
                ? SizedBox(
                    width: isDesktop ? 20 : 18.w,
                    height: isDesktop ? 20 : 18.h,
                    child: const CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Image.asset(
                    'assets/icons/whatsapp.png', // ✅ أيقونة واتساب
                    width: isDesktop ? 24 : 22.w,
                    height: isDesktop ? 24 : 22.h,
                    color: AppColors.white,
                  ),
            label: Text(
              primaryContact != null
                  ? 'location.send_to_primary'.tr(args: [primaryContact.name])
                  : 'location.send_to_primary_disabled'.tr(),
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 12 : 10.h),

        // Secondary Button - Share with All
        SizedBox(
          width: double.infinity,
          height: isDesktop ? 52 : 48.h,
          child: OutlinedButton.icon(
            onPressed: _shareWithAll,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              Icons.share,
              color: AppColors.primary,
              size: isDesktop ? 20 : 18.sp,
            ),
            label: Text(
              'location.share_with_all'.tr(),
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        SizedBox(height: isDesktop ? 12 : 10.h),

        // Manage Contacts Button
        TextButton(
          onPressed: _openManageContacts,
          child: Text(
            'location.manage_contacts'.tr(),
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13.sp,
              color: AppColors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        SizedBox(height: isDesktop ? 16 : 16.h),
      ],
    );
  }

  // Info Row Widget
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDesktop,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: isDesktop ? 20 : 18.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: isDesktop ? 8 : 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13.sp,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Get accuracy color
  Color _getAccuracyColor(String level) {
    switch (level) {
      case 'high':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  // Get battery color
  Color _getBatteryColor(int level) {
    if (level >= 50) return AppColors.success;
    if (level >= 20) return AppColors.warning;
    return AppColors.error;
  }
}
