import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

/// شاشة خاصة لطلب إذن الموقع في الخلفية
/// Google Play يتطلب شرحاً واضحاً ومفصلاً لهذا الإذن
class BackgroundLocationPermissionScreen extends StatelessWidget {
  final VoidCallback onGranted;
  final VoidCallback? onDenied;

  const BackgroundLocationPermissionScreen({
    super.key,
    required this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                            Icons.my_location,
                            size: 60.sp,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Title
                      Text(
                        'تتبع الموقع في الخلفية',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Main Description
                      Text(
                        'لضمان سلامتك، يحتاج التطبيق لمعرفة موقعك حتى عندما لا تستخدم التطبيق بشكل نشط.',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Why Section
                      _buildSectionTitle('لماذا نحتاج هذا الإذن؟'),
                      SizedBox(height: 16.h),
                      
                      _buildBenefit(
                        icon: Icons.emergency,
                        title: 'حالات الطوارئ',
                        description: 'إرسال موقعك الفوري لجهات الاتصال الطارئة عند الضغط على زر الطوارئ',
                      ),
                      
                      _buildBenefit(
                        icon: Icons.family_restroom,
                        title: 'راحة بال الأسرة',
                        description: 'يمكن لأفراد عائلتك الاطمئان على موقعك في أي وقت',
                      ),
                      
                      _buildBenefit(
                        icon: Icons.notifications_active,
                        title: 'تنبيهات ذكية',
                        description: 'تلقي تذكيرات بناءً على موقعك (مثل: تذكير بالدواء عند الوصول للمنزل)',
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // How it works
                      _buildSectionTitle('كيف يعمل؟'),
                      SizedBox(height: 16.h),
                      
                      _buildStep(
                        number: '1',
                        text: 'التطبيق يتتبع موقعك بشكل دوري في الخلفية',
                      ),
                      
                      _buildStep(
                        number: '2',
                        text: 'عند الضغط على زر الطوارئ، يُرسل موقعك فوراً',
                      ),
                      
                      _buildStep(
                        number: '3',
                        text: 'يمكنك إيقاف التتبع في أي وقت من الإعدادات',
                      ),
                      
                      SizedBox(height: 32.h),
                      
                      // Privacy Note
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.privacy_tip,
                              color: Colors.blue.shade700,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'خصوصيتك مهمة',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'موقعك مشفر ومحمي. لا نشاركه مع أي طرف ثالث بدون موافقتك.',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.blue.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Battery Note
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.battery_charging_full,
                              color: Colors.green.shade700,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'مُحسّن لاستهلاك البطارية: نستخدم تقنيات موفرة للطاقة',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        'السماح بالتتبع في الخلفية',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDenied?.call();
                    },
                    child: Text(
                      'ربما لاحقاً',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required String number, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission(BuildContext context) async {
    // أولاً: التأكد من أن إذن الموقع العادي ممنوح
    final locationStatus = await Permission.location.status;
    
    if (!locationStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب منح إذن الموقع أولاً'),
        ),
      );
      return;
    }
    
    // ثانياً: طلب إذن الموقع في الخلفية
    final status = await Permission.locationAlways.request();
    
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
          'لتفعيل تتبع الموقع في الخلفية، يرجى:\n\n'
          '1. فتح الإعدادات\n'
          '2. اختيار "الأذونات"\n'
          '3. اختيار "الموقع"\n'
          '4. اختيار "السماح طوال الوقت"',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
