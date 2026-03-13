import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/permission_info.dart';

class PermissionRequestScreen extends StatelessWidget {
  final PermissionInfo permissionInfo;
  final Permission permission;
  final VoidCallback onGranted;
  final VoidCallback? onDenied;

  const PermissionRequestScreen({
    super.key,
    required this.permissionInfo,
    required this.permission,
    required this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40.h),
                      
                      // Icon
                      Center(
                        child: Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(),
                            size: 60.sp,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Title
                      Text(
                        permissionInfo.title,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Description
                      Text(
                        permissionInfo.description,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Benefits
                      Text(
                        'لماذا نحتاج هذا الإذن؟',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      ...permissionInfo.benefits.map((benefit) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF2E7D32),
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                benefit,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      
                      if (permissionInfo.isRequired) ...[
                        SizedBox(height: 24.h),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  'هذا الإذن مطلوب لعمل الميزة بشكل صحيح',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () => _requestPermission(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'منح الإذن',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  if (!permissionInfo.isRequired) ...[
                    SizedBox(height: 12.h),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDenied?.call();
                      },
                      child: Text(
                        'تخطي الآن',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData() {
    switch (permissionInfo.icon) {
      case 'location':
        return Icons.location_on;
      case 'camera':
        return Icons.camera_alt;
      case 'notification':
        return Icons.notifications;
      case 'photos':
        return Icons.photo_library;
      default:
        return Icons.security;
    }
  }

  Future<void> _requestPermission(BuildContext context) async {
    final status = await permission.request();
    
    if (status.isGranted) {
      Navigator.pop(context);
      onGranted();
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(context);
    } else {
      Navigator.pop(context);
      onDenied?.call();
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإذن مطلوب'),
        content: const Text(
          'لقد رفضت هذا الإذن سابقاً. يرجى الذهاب إلى الإعدادات لتفعيله.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
