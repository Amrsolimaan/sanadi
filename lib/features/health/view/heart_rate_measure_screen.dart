// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:camera/camera.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../core/localization/language_cubit.dart';
// import '../model/heart_rate_model.dart';
// import '../viewmodel/health_cubit.dart';
// import '../viewmodel/health_state.dart';

// class HeartRateMeasureScreen extends StatefulWidget {
//   const HeartRateMeasureScreen({super.key});

//   @override
//   State<HeartRateMeasureScreen> createState() => _HeartRateMeasureScreenState();
// }

// class _HeartRateMeasureScreenState extends State<HeartRateMeasureScreen>
//     with SingleTickerProviderStateMixin {
//   List<CameraDescription> _cameras = [];
//   bool _isCameraReady = false;

//   // للأنيميشن
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCameras();

//     // تهيئة الأنيميشن
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1000),
//     )..repeat(reverse: true);

//     _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeCameras() async {
//     try {
//       _cameras = await availableCameras();
//       setState(() {
//         _isCameraReady = _cameras.isNotEmpty;
//       });
//     } catch (e) {
//       debugPrint('Error initializing cameras: $e');
//     }
//   }

//   bool _isLargeScreen(BuildContext context) {
//     return MediaQuery.of(context).size.width > 800;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isLarge = _isLargeScreen(context);
//     final lang = context.locale.languageCode;

//     return BlocBuilder<LanguageCubit, LanguageState>(
//       builder: (context, languageState) {
//         return BlocConsumer<HealthCubit, HealthState>(
//           listener: (context, state) {
//             if (state is HeartRateSaved) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('health.saved'.tr()),
//                   backgroundColor: AppColors.success,
//                 ),
//               );
//               Navigator.pop(context);
//             }
//           },
//           builder: (context, state) {
//             return Scaffold(
//               backgroundColor: AppColors.background,
//               appBar: AppBar(
//                 backgroundColor: AppColors.background,
//                 elevation: 0,
//                 leading: IconButton(
//                   icon: const Icon(Icons.arrow_back,
//                       color: AppColors.textPrimary),
//                   onPressed: () {
//                     context.read<HealthCubit>().cancelMeasuring();
//                     Navigator.pop(context);
//                   },
//                 ),
//                 title: Text(
//                   'health.measure_heart_rate'.tr(),
//                   style: TextStyle(
//                     fontSize: isLarge ? 20 : 18.sp,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textPrimary,
//                   ),
//                 ),
//                 centerTitle: true,
//               ),
//               body: SafeArea(
//                 child: _buildContent(context, state, lang, isLarge),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildContent(
//       BuildContext context, HealthState state, String lang, bool isLarge) {
//     // حالة التوجيه (كشف الإصبع)
//     if (state is HeartRateMeasureGuiding) {
//       return _buildGuidingStateImproved(context, state, lang, isLarge);
//     }

//     // Ready state - show instructions
//     if (state is HeartRateMeasureReady ||
//         state is HealthInitial ||
//         state is HealthLoaded) {
//       return _buildReadyStateImproved(context, lang, isLarge);
//     }

//     // Measuring state
//     if (state is HeartRateMeasuring) {
//       return _buildMeasuringState(context, state, lang, isLarge);
//     }

//     // Complete state
//     if (state is HeartRateMeasureComplete) {
//       return _buildCompleteState(context, state, lang, isLarge);
//     }

//     // Error state
//     if (state is HeartRateMeasureError) {
//       return _buildErrorState(context, state, lang, isLarge);
//     }

//     return _buildReadyStateImproved(context, lang, isLarge);
//   }

//   /// ⭐ واجهة التوجيه المحسّنة - مرحلة كشف الإصبع
//   Widget _buildGuidingStateImproved(BuildContext context,
//       HeartRateMeasureGuiding state, String lang, bool isLarge) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: EdgeInsets.all(isLarge ? 32 : 20.w),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SizedBox(height: isLarge ? 40 : 20.h),

//             // أيقونة متحركة للإصبع
//             AnimatedBuilder(
//               animation: _scaleAnimation,
//               builder: (context, child) {
//                 return Transform.scale(
//                   scale: _scaleAnimation.value,
//                   child: Container(
//                     width: isLarge ? 140 : 120.w,
//                     height: isLarge ? 140 : 120.h,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withOpacity(0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.fingerprint,
//                       size: isLarge ? 80 : 64.sp,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                 );
//               },
//             ),

//             SizedBox(height: isLarge ? 40 : 32.h),

//             // رسالة التوجيه
//             Text(
//               state.message,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: isLarge ? 20 : 18.sp,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.textPrimary,
//               ),
//             ),

//             SizedBox(height: isLarge ? 24 : 20.h),

//             // مؤشر التحميل
//             SizedBox(
//               width: isLarge ? 48 : 40.w,
//               height: isLarge ? 48 : 40.h,
//               child: const CircularProgressIndicator(
//                 strokeWidth: 3,
//                 valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
//               ),
//             ),

//             SizedBox(height: isLarge ? 48 : 36.h),

//             // ⭐ رسم توضيحي محسّن لكيفية وضع الإصبع
//             _buildFingerPlacementDiagram(lang, isLarge),

//             SizedBox(height: isLarge ? 32 : 24.h),

//             // تعليمات مرئية محسّنة
//             _buildImprovedInstructions(lang, isLarge),

//             SizedBox(height: isLarge ? 40 : 32.h),

//             // زر إلغاء
//             TextButton(
//               onPressed: () {
//                 context.read<HealthCubit>().cancelMeasuring();
//                 Navigator.pop(context);
//               },
//               child: Text(
//                 lang == 'ar' ? 'إلغاء' : 'Cancel',
//                 style: TextStyle(
//                   fontSize: isLarge ? 14 : 13.sp,
//                   color: AppColors.textSecondary,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// ⭐ رسم توضيحي لكيفية وضع الإصبع
//   Widget _buildFingerPlacementDiagram(String lang, bool isLarge) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: isLarge ? 40 : 24.w),
//       padding: EdgeInsets.all(isLarge ? 24 : 20.w),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppColors.primary.withOpacity(0.1),
//             AppColors.primary.withOpacity(0.05),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: AppColors.primary.withOpacity(0.3),
//           width: 2,
//         ),
//       ),
//       child: Column(
//         children: [
//           // عنوان
//           Text(
//             lang == 'ar' ? '📱 كيف تضع إصبعك؟' : '📱 How to place your finger?',
//             style: TextStyle(
//               fontSize: isLarge ? 18 : 16.sp,
//               fontWeight: FontWeight.bold,
//               color: AppColors.primary,
//             ),
//           ),

//           SizedBox(height: isLarge ? 20 : 16.h),

//           // رسم بسيط يوضح الهاتف والإصبع
//           Container(
//             width: double.infinity,
//             height: isLarge ? 160 : 140.h,
//             decoration: BoxDecoration(
//               color: AppColors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 // الهاتف (مستطيل)
//                 Container(
//                   width: isLarge ? 100 : 80.w,
//                   height: isLarge ? 140 : 120.h,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey, width: 3),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Column(
//                     children: [
//                       SizedBox(height: isLarge ? 12 : 10.h),
//                       // الكاميرا
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             width: isLarge ? 16 : 14.w,
//                             height: isLarge ? 16 : 14.h,
//                             decoration: BoxDecoration(
//                               color: Colors.black87,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                   color: AppColors.primary, width: 2),
//                             ),
//                           ),
//                           SizedBox(width: isLarge ? 8 : 6.w),
//                           // الفلاش
//                           Container(
//                             width: isLarge ? 12 : 10.w,
//                             height: isLarge ? 12 : 10.h,
//                             decoration: BoxDecoration(
//                               color: Colors.amber,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                   color: AppColors.primary, width: 2),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // الإصبع (من الأعلى)
//                 Positioned(
//                   top: isLarge ? -10 : -5,
//                   child: Container(
//                     width: isLarge ? 70 : 60.w,
//                     height: isLarge ? 80 : 70.h,
//                     decoration: BoxDecoration(
//                       color: Colors.brown.shade300.withOpacity(0.8),
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(30),
//                         bottomRight: Radius.circular(30),
//                         topLeft: Radius.circular(20),
//                         topRight: Radius.circular(20),
//                       ),
//                     ),
//                     child: Center(
//                       child: Text(
//                         '👆',
//                         style: TextStyle(fontSize: isLarge ? 32 : 28.sp),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // سهم يشير إلى الوضع الصحيح
//                 Positioned(
//                   right: isLarge ? 10 : 5,
//                   child: Icon(
//                     Icons.check_circle,
//                     color: AppColors.success,
//                     size: isLarge ? 32 : 28.sp,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           SizedBox(height: isLarge ? 16 : 14.h),

//           // شرح نصي
//           Text(
//             lang == 'ar'
//                 ? 'ضع طرف إصبعك بشكل مسطح\nبحيث يغطي الكاميرا والفلاش معاً'
//                 : 'Place your fingertip flat\nto cover both camera and flash',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: isLarge ? 13 : 12.sp,
//               color: AppColors.textSecondary,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// ⭐ تعليمات محسّنة
//   Widget _buildImprovedInstructions(String lang, bool isLarge) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: isLarge ? 24 : 16.w),
//       padding: EdgeInsets.all(isLarge ? 24 : 20.w),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // عنوان
//           Row(
//             children: [
//               Icon(
//                 Icons.info_outline,
//                 color: AppColors.primary,
//                 size: isLarge ? 24 : 20.sp,
//               ),
//               SizedBox(width: isLarge ? 12 : 10.w),
//               Text(
//                 lang == 'ar' ? 'نصائح مهمة:' : 'Important Tips:',
//                 style: TextStyle(
//                   fontSize: isLarge ? 16 : 14.sp,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             ],
//           ),

//           SizedBox(height: isLarge ? 16 : 14.h),

//           // التعليمات
//           _buildInstructionItem(
//             Icons.touch_app,
//             lang == 'ar'
//                 ? 'ضع طرف إصبعك بشكل مسطح (ليس عمودي)'
//                 : 'Place your fingertip flat (not vertical)',
//             isLarge,
//           ),
//           SizedBox(height: isLarge ? 12 : 10.h),
//           _buildInstructionItem(
//             Icons.camera,
//             lang == 'ar'
//                 ? 'غطِ عدسة الكاميرا والفلاش معاً بالكامل'
//                 : 'Cover both camera lens and flash completely',
//             isLarge,
//           ),
//           SizedBox(height: isLarge ? 12 : 10.h),
//           _buildInstructionItem(
//             Icons.pan_tool,
//             lang == 'ar'
//                 ? 'اضغط بلطف دون قوة (لا تضغط بشدة)'
//                 : 'Press gently without force (don\'t press hard)',
//             isLarge,
//           ),
//           SizedBox(height: isLarge ? 12 : 10.h),
//           _buildInstructionItem(
//             Icons.self_improvement,
//             lang == 'ar'
//                 ? 'ابق ثابتاً تماماً ولا تتحرك'
//                 : 'Stay completely still and don\'t move',
//             isLarge,
//           ),
//           SizedBox(height: isLarge ? 12 : 10.h),
//           _buildInstructionItem(
//             Icons.timer,
//             lang == 'ar'
//                 ? 'انتظر 30 ثانية للحصول على نتيجة دقيقة'
//                 : 'Wait 30 seconds for accurate result',
//             isLarge,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInstructionItem(IconData icon, String text, bool isLarge) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: isLarge ? 32 : 28.w,
//           height: isLarge ? 32 : 28.h,
//           decoration: BoxDecoration(
//             color: AppColors.primary.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             icon,
//             size: isLarge ? 18 : 16.sp,
//             color: AppColors.primary,
//           ),
//         ),
//         SizedBox(width: isLarge ? 12 : 10.w),
//         Expanded(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: isLarge ? 13 : 12.sp,
//               color: AppColors.textSecondary,
//               height: 1.4,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   /// ⭐ واجهة Ready المحسّنة
//   Widget _buildReadyStateImproved(
//       BuildContext context, String lang, bool isLarge) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: EdgeInsets.all(isLarge ? 32 : 20.w),
//         child: Column(
//           children: [
//             SizedBox(height: isLarge ? 20 : 10.h),

//             // أيقونة القلب
//             Container(
//               width: isLarge ? 120 : 100.w,
//               height: isLarge ? 120 : 100.h,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppColors.primary,
//                     AppColors.primary.withOpacity(0.7),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.primary.withOpacity(0.3),
//                     blurRadius: 20,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 Icons.favorite,
//                 size: isLarge ? 60 : 50.sp,
//                 color: AppColors.white,
//               ),
//             ),

//             SizedBox(height: isLarge ? 32 : 24.h),

//             // العنوان
//             Text(
//               lang == 'ar' ? 'قياس معدل ضربات القلب' : 'Heart Rate Measurement',
//               style: TextStyle(
//                 fontSize: isLarge ? 24 : 20.sp,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.textPrimary,
//               ),
//             ),

//             SizedBox(height: isLarge ? 12 : 10.h),

//             Text(
//               lang == 'ar'
//                   ? 'اتبع التعليمات للحصول على قياس دقيق'
//                   : 'Follow instructions for accurate measurement',
//               style: TextStyle(
//                 fontSize: isLarge ? 14 : 13.sp,
//                 color: AppColors.textSecondary,
//               ),
//               textAlign: TextAlign.center,
//             ),

//             SizedBox(height: isLarge ? 40 : 32.h),

//             // الرسم التوضيحي
//             _buildFingerPlacementDiagram(lang, isLarge),

//             SizedBox(height: isLarge ? 32 : 24.h),

//             // التعليمات
//             _buildImprovedInstructions(lang, isLarge),

//             SizedBox(height: isLarge ? 40 : 32.h),

//             // زر البدء
//             SizedBox(
//               width: double.infinity,
//               height: isLarge ? 56 : 50.h,
//               child: ElevatedButton(
//                 onPressed: _isCameraReady
//                     ? () => context.read<HealthCubit>().startMeasuring(_cameras)
//                     : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 4,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.play_arrow,
//                       color: AppColors.white,
//                       size: isLarge ? 28 : 24.sp,
//                     ),
//                     SizedBox(width: isLarge ? 12 : 10.w),
//                     Text(
//                       lang == 'ar' ? 'ابدأ القياس' : 'Start Measurement',
//                       style: TextStyle(
//                         fontSize: isLarge ? 18 : 16.sp,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             if (!_isCameraReady) ...[
//               SizedBox(height: isLarge ? 16 : 12.h),
//               Text(
//                 lang == 'ar'
//                     ? 'جاري تهيئة الكاميرا...'
//                     : 'Initializing camera...',
//                 style: TextStyle(
//                   fontSize: isLarge ? 12 : 11.sp,
//                   color: AppColors.textHint,
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGuidingInstruction(IconData icon, String text, bool isLarge) {
//     return Row(
//       children: [
//         Icon(icon, color: AppColors.primary, size: isLarge ? 20 : 18.sp),
//         SizedBox(width: isLarge ? 12 : 10.w),
//         Expanded(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: isLarge ? 13 : 12.sp,
//               color: AppColors.textPrimary,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMeasuringState(BuildContext context, HeartRateMeasuring state,
//       String lang, bool isLarge) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(isLarge ? 32 : 16.w),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Animated Heart
//             TweenAnimationBuilder<double>(
//               tween: Tween(begin: 0.8, end: 1.2),
//               duration: const Duration(milliseconds: 600),
//               builder: (context, scale, child) {
//                 return Transform.scale(
//                   scale: scale,
//                   child: Text(
//                     '❤️',
//                     style: TextStyle(fontSize: isLarge ? 80 : 64.sp),
//                   ),
//                 );
//               },
//               onEnd: () {
//                 setState(() {});
//               },
//             ),

//             SizedBox(height: isLarge ? 32 : 24.h),

//             // Progress Circle
//             SizedBox(
//               width: isLarge ? 200 : 160.w,
//               height: isLarge ? 200 : 160.h,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   CircularProgressIndicator(
//                     value: state.progress / 100,
//                     strokeWidth: isLarge ? 12 : 10,
//                     backgroundColor: AppColors.primary.withOpacity(0.1),
//                     valueColor: const AlwaysStoppedAnimation(AppColors.primary),
//                   ),
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         '${((100 - state.progress) * 30 / 100).ceil()}', // حساب الثواني المتبقية (30 ثانية * النسبة المتبقية)
//                         style: TextStyle(
//                           fontSize: isLarge ? 48 : 40.sp,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                       Text(
//                         lang == 'ar' ? 'ثانية' : 'sec',
//                         style: TextStyle(
//                           fontSize: isLarge ? 16 : 14.sp,
//                           color: AppColors.textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             SizedBox(height: isLarge ? 32 : 24.h),

//             // Message
//             if (state.message != null)
//               Text(
//                 state.message!,
//                 style: TextStyle(
//                   fontSize: isLarge ? 16 : 14.sp,
//                   color: AppColors.textSecondary,
//                 ),
//                 textAlign: TextAlign.center,
//               ),

//             SizedBox(height: isLarge ? 24 : 16.h),

//             // Readings count
//             Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: isLarge ? 24 : 16.w,
//                 vertical: isLarge ? 12 : 8.h,
//               ),
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 '${state.readings.length} ${lang == 'ar' ? 'قراءة' : 'readings'}',
//                 style: TextStyle(
//                   fontSize: isLarge ? 12 : 11.sp,
//                   color: AppColors.primary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),

//             SizedBox(height: isLarge ? 32 : 24.h),

//             // Warning
//             Container(
//               padding: EdgeInsets.all(isLarge ? 16 : 14.w),
//               decoration: BoxDecoration(
//                 color: AppColors.warning.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: AppColors.warning.withOpacity(0.3),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.warning_amber,
//                     color: AppColors.warning,
//                     size: isLarge ? 24 : 20.sp,
//                   ),
//                   SizedBox(width: isLarge ? 12 : 10.w),
//                   Expanded(
//                     child: Text(
//                       lang == 'ar'
//                           ? 'لا تزل إصبعك حتى انتهاء القياس'
//                           : 'Don\'t remove your finger until complete',
//                       style: TextStyle(
//                         fontSize: isLarge ? 13 : 12.sp,
//                         color: AppColors.warning,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCompleteState(BuildContext context,
//       HeartRateMeasureComplete state, String lang, bool isLarge) {
//     // تحويل category من String إلى enum
//     HeartRateCategory categoryEnum;
//     if (state.category == 'low') {
//       categoryEnum = HeartRateCategory.low;
//     } else if (state.category == 'high') {
//       categoryEnum = HeartRateCategory.high;
//     } else {
//       categoryEnum = HeartRateCategory.normal;
//     }

//     final colorValue = HeartRateModel.getCategoryColorValue(categoryEnum);
//     final categoryIcon = HeartRateModel.getCategoryIcon(categoryEnum);

//     final categoryLabel = {
//       HeartRateCategory.low: lang == 'ar' ? 'منخفض' : 'Low',
//       HeartRateCategory.normal: lang == 'ar' ? 'طبيعي' : 'Normal',
//       HeartRateCategory.high: lang == 'ar' ? 'مرتفع' : 'High',
//     }[categoryEnum]!;

//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(isLarge ? 32 : 16.w),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Success Icon
//             Container(
//               width: isLarge ? 100 : 80.w,
//               height: isLarge ? 100 : 80.h,
//               decoration: const BoxDecoration(
//                 color: AppColors.success,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.check,
//                 size: isLarge ? 50 : 40.sp,
//                 color: AppColors.white,
//               ),
//             ),

//             SizedBox(height: isLarge ? 24 : 16.h),

//             // Heart Icon
//             Text(
//               '❤️',
//               style: TextStyle(fontSize: isLarge ? 48 : 40.sp),
//             ),

//             SizedBox(height: isLarge ? 16 : 12.h),

//             // BPM
//             Text(
//               '${state.bpm} BPM',
//               style: TextStyle(
//                 fontSize: isLarge ? 48 : 40.sp,
//                 fontWeight: FontWeight.bold,
//                 color: AppColors.textPrimary,
//               ),
//             ),

//             SizedBox(height: isLarge ? 12 : 8.h),

//             // Category
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   categoryIcon,
//                   style: TextStyle(fontSize: isLarge ? 20 : 18.sp),
//                 ),
//                 SizedBox(width: isLarge ? 8 : 6.w),
//                 Text(
//                   categoryLabel,
//                   style: TextStyle(
//                     fontSize: isLarge ? 18 : 16.sp,
//                     fontWeight: FontWeight.w600,
//                     color: Color(colorValue),
//                   ),
//                 ),
//               ],
//             ),

//             SizedBox(height: isLarge ? 8 : 6.h),

//             Text(
//               '(60-100 BPM ${lang == 'ar' ? 'طبيعي' : 'is normal'})',
//               style: TextStyle(
//                 fontSize: isLarge ? 12 : 11.sp,
//                 color: AppColors.textHint,
//               ),
//             ),

//             // عرض جودة الإشارة إن وجدت
//             if (state.signalQuality != null) ...[
//               SizedBox(height: isLarge ? 12 : 10.h),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: isLarge ? 16 : 12.w,
//                   vertical: isLarge ? 8 : 6.h,
//                 ),
//                 decoration: BoxDecoration(
//                   color:
//                       _getQualityColor(state.signalQuality!).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       _getQualityIcon(state.signalQuality!),
//                       size: isLarge ? 16 : 14.sp,
//                       color: _getQualityColor(state.signalQuality!),
//                     ),
//                     SizedBox(width: isLarge ? 6 : 4.w),
//                     Text(
//                       _getQualityText(state.signalQuality!, lang),
//                       style: TextStyle(
//                         fontSize: isLarge ? 11 : 10.sp,
//                         color: _getQualityColor(state.signalQuality!),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             SizedBox(height: isLarge ? 48 : 32.h),

//             // Save Button
//             SizedBox(
//               width: double.infinity,
//               height: isLarge ? 56 : 48.h,
//               child: ElevatedButton(
//                 onPressed: () =>
//                     context.read<HealthCubit>().saveHeartRate(state.bpm),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   'health.save_result'.tr(),
//                   style: TextStyle(
//                     fontSize: isLarge ? 16 : 14.sp,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.white,
//                   ),
//                 ),
//               ),
//             ),

//             SizedBox(height: isLarge ? 16 : 12.h),

//             // Measure Again
//             TextButton(
//               onPressed: () {
//                 context.read<HealthCubit>().startMeasuring(_cameras);
//               },
//               child: Text(
//                 'health.measure_again'.tr(),
//                 style: TextStyle(
//                   fontSize: isLarge ? 14 : 13.sp,
//                   color: AppColors.primary,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // دوال مساعدة لجودة الإشارة
//   Color _getQualityColor(double quality) {
//     if (quality >= 0.8) return AppColors.success;
//     if (quality >= 0.5) return AppColors.warning;
//     return AppColors.error;
//   }

//   IconData _getQualityIcon(double quality) {
//     if (quality >= 0.8) return Icons.check_circle;
//     if (quality >= 0.5) return Icons.warning_amber;
//     return Icons.error;
//   }

//   String _getQualityText(double quality, String lang) {
//     if (quality >= 0.8) {
//       return lang == 'ar' ? 'جودة ممتازة' : 'Excellent Quality';
//     }
//     if (quality >= 0.5) {
//       return lang == 'ar' ? 'جودة جيدة' : 'Good Quality';
//     }
//     return lang == 'ar' ? 'جودة منخفضة' : 'Low Quality';
//   }

//   Widget _buildErrorState(BuildContext context, HeartRateMeasureError state,
//       String lang, bool isLarge) {
//     return Center(
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(isLarge ? 32 : 20.w),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.error_outline,
//                 size: isLarge ? 80 : 64.sp,
//                 color: AppColors.error,
//               ),
//               SizedBox(height: isLarge ? 24 : 16.h),
//               Text(
//                 'health.measurement_failed'.tr(),
//                 style: TextStyle(
//                   fontSize: isLarge ? 20 : 18.sp,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//               SizedBox(height: isLarge ? 16 : 12.h),
//               Container(
//                 padding: EdgeInsets.all(isLarge ? 20 : 16.w),
//                 decoration: BoxDecoration(
//                   color: AppColors.error.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: AppColors.error.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Text(
//                   state.message,
//                   style: TextStyle(
//                     fontSize: isLarge ? 14 : 13.sp,
//                     color: AppColors.textPrimary,
//                     height: 1.5,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               SizedBox(height: isLarge ? 32 : 24.h),
//               SizedBox(
//                 width: double.infinity,
//                 height: isLarge ? 56 : 48.h,
//                 child: ElevatedButton(
//                   onPressed: () =>
//                       context.read<HealthCubit>().startMeasuring(_cameras),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     'health.try_again'.tr(),
//                     style: TextStyle(
//                       fontSize: isLarge ? 16 : 14.sp,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
