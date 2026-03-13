import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ إضافة مكتبة Geocoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LatLng? _currentLocation;
  String _addressText = '';
  String _fullAddress = ''; // ✅ إضافة العنوان الكامل
  double _accuracy = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGeocodingLoading = false; // ✅ حالة تحميل Geocoding
  String? _errorMessage;
  StreamSubscription<Position>? _positionStreamSubscription;
  DateTime? _lastUpdated;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ✅ مباشرة نبدأ التهيئة بدون setState إضافي
    _initLocationService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed, reinitializing location...');
      _initLocationService();
    }
  }

  /// تهيئة خدمة الموقع
  Future<void> _initLocationService() async {
    // ✅ الحل: نضبط الحالة مرة واحدة فقط في البداية
    if (mounted) {
      setState(() {
        _isLoading = true;
        // ✅ لا نمسح _errorMessage هنا - ندعه كما هو
      });
    }

    print('🚀 Initializing location service...');

    try {
      // التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location service is disabled');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'address.service_disabled'.tr();
          });
        }
        return;
      }
      print('✅ Location service is enabled');

      // التحقق من الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        print('⚠️ Permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        print('🔐 New permission: $permission');

        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'address.permission_denied'.tr();
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permission denied forever');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'address.permission_denied_forever'.tr();
          });
        }
        return;
      }

      print('✅ Permissions granted');

      // الحصول على الموقع الحالي
      await _getCurrentLocation();

      // بدء الاستماع لتحديثات الموقع
      _startLocationUpdates();
    } catch (e) {
      print('❌ Error in init: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'address.failed_to_get_location'.tr();
        });
      }
    }
  }

  /// الحصول على الموقع الحالي
  Future<void> _getCurrentLocation() async {
    try {
      print('📍 Requesting current location...');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      ).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      _updateLocation(position);
    } on TimeoutException catch (e) {
      print('⏱️ Timeout: $e');
      // حاول مرة أخرى بدقة أقل
      try {
        print('🔄 Retrying with medium accuracy...');
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 30),
        );
        print(
            '✅ Location obtained (medium): ${position.latitude}, ${position.longitude}');
        _updateLocation(position);
      } catch (e2) {
        print('❌ Medium accuracy also failed: $e2');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'address.failed_to_get_location'.tr();
          });
        }
      }
    } catch (e) {
      print('❌ Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'address.failed_to_get_location'.tr();
        });
      }
    }
  }

  /// بدء الاستماع لتحديثات الموقع المستمرة
  void _startLocationUpdates() {
    print('🎧 Starting location stream...');

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        print(
            '📍 Location updated: ${position.latitude}, ${position.longitude}');
        _updateLocation(position);
        _saveLocationToFirebase();
      },
      onError: (e) {
        print('❌ Location stream error: $e');
      },
    );
  }

  /// تحديث الموقع في الواجهة
  void _updateLocation(Position position) {
    if (mounted) {
      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = newLocation;
        _accuracy = position.accuracy;
        _lastUpdated = DateTime.now();
        _isLoading = false;
        _errorMessage = null;
        // ✅ إزالة تحديث _addressText هنا - سيتم تحديثه في _getAddressFromCoordinates
        
        // ✅ تحديث Marker
        _markers = {
          Marker(
            markerId: const MarkerId('current_location'),
            position: newLocation,
            infoWindow: InfoWindow(title: 'address.current_location'.tr()),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
          ),
        };
      });

      // تحريك الخريطة للموقع الجديد
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLocation, zoom: 16.0),
        ),
      );

      // ✅ الحصول على العنوان من الإحداثيات
      _getAddressFromCoordinates(position.latitude, position.longitude);
    }
  }

  /// ✅ تحويل الإحداثيات إلى عنوان باستخدام Geocoding
  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    if (!mounted) return;

    setState(() {
      _isGeocodingLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        
        // بناء العنوان حسب اللغة
        String formattedAddress = '';
        
        if (context.locale.languageCode == 'ar') {
          // للعربية: نبدأ بالتفاصيل الأصغر
          List<String> addressParts = [];
          
          if (place.name != null && place.name!.isNotEmpty) {
            addressParts.add(place.name!);
          }
          if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          
          formattedAddress = addressParts.join('، ');
        } else {
          // للإنجليزية: نبدأ بالتفاصيل الأكبر
          List<String> addressParts = [];
          
          if (place.name != null && place.name!.isNotEmpty) {
            addressParts.add(place.name!);
          }
          if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
            addressParts.add(place.street!);
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }
          
          formattedAddress = addressParts.join(', ');
        }

        setState(() {
          _fullAddress = formattedAddress.isNotEmpty 
              ? formattedAddress 
              : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
          // ✅ تحديث _addressText أيضاً ليكون نصي
          _addressText = formattedAddress.isNotEmpty 
              ? formattedAddress 
              : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
          _isGeocodingLoading = false;
        });
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
      if (mounted) {
        setState(() {
          _fullAddress = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
          // ✅ تحديث _addressText في حالة الخطأ أيضاً
          _addressText = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
          _isGeocodingLoading = false;
        });
      }
    }
  }

  /// حفظ الموقع في Firebase
  Future<void> _saveLocationToFirebase() async {
    if (_currentLocation == null || _isSaving) return;

    final user = _auth.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() => _isSaving = true);
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'location': {
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
          'accuracy': _accuracy,
          'address': _fullAddress.isNotEmpty ? _fullAddress : _addressText, // ✅ حفظ العنوان الكامل
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
      print('✅ Location saved to Firebase');
      
      // ✅ إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.locale.languageCode == 'ar' 
                  ? 'تم حفظ الموقع بنجاح' 
                  : 'Location saved successfully',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving location: $e');
      
      // ✅ إظهار رسالة خطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.locale.languageCode == 'ar' 
                  ? 'فشل في حفظ الموقع' 
                  : 'Failed to save location',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// فتح إعدادات الموقع
  Future<void> _openLocationSettings() async {
    print('⚙️ Opening location settings...');
    await Geolocator.openLocationSettings();
  }

  /// فتح إعدادات التطبيق
  Future<void> _openAppSettings() async {
    print('⚙️ Opening app settings...');
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'address.title'.tr(),
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      // ✅ إضافة SafeArea
      body: SafeArea(
        child: Column(
          children: [
            // الخريطة
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // ✅ منطق العرض المُحسّن
                  if (_isLoading)
                    // Loading Indicator
                    Container(
                      color: AppColors.scaffoldBackground,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: 16.h),
                            Text(
                              'address.loading'.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_errorMessage != null)
                    // Error Message
                    Container(
                      color: AppColors.scaffoldBackground,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64.sp,
                                color: AppColors.error,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              // أزرار الإجراءات حسب نوع الخطأ
                              if (_errorMessage ==
                                  'address.service_disabled'.tr())
                                ElevatedButton.icon(
                                  onPressed: _openLocationSettings,
                                  icon: const Icon(Icons.settings,
                                      color: AppColors.white),
                                  label: Text(
                                    'address.enable_service'.tr(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                      vertical: 12.h,
                                    ),
                                  ),
                                )
                              else if (_errorMessage ==
                                  'address.permission_denied_forever'.tr())
                                ElevatedButton.icon(
                                  onPressed: _openAppSettings,
                                  icon: const Icon(Icons.settings,
                                      color: AppColors.white),
                                  label: Text(
                                    'address.open_settings'.tr(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                      vertical: 12.h,
                                    ),
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _initLocationService,
                                  icon: const Icon(Icons.refresh,
                                      color: AppColors.white),
                                  label: Text(
                                    'address.retry'.tr(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                      vertical: 12.h,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // ✅ Google Map
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation ?? const LatLng(30.0444, 31.2357),
                        zoom: 16.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _markers,
                      onTap: (LatLng position) {
                        // يمكن إضافة وظيفة تغيير الموقع بالضغط
                      },
                    ),
                  // زر تحديد الموقع الحالي
                  if (!_isLoading && _errorMessage == null)
                    Positioned(
                      bottom: 16.h,
                      right: 16.w,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: AppColors.white,
                        onPressed: () {
                          _getCurrentLocation();
                          // ✅ إعادة تحديد العنوان أيضاً
                          if (_currentLocation != null) {
                            _getAddressFromCoordinates(
                              _currentLocation!.latitude, 
                              _currentLocation!.longitude
                            );
                          }
                        },
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  // مؤشر التحديث المستمر
                  if (!_isLoading && _errorMessage == null)
                    Positioned(
                      top: 16.h,
                      left: 16.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'address.live'.tr(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // معلومات الموقع
            if (!_isLoading && _errorMessage == null)
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24.r)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'address.current_location'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _isGeocodingLoading 
                                          ? (context.locale.languageCode == 'ar' 
                                              ? 'جاري تحديد العنوان...' 
                                              : 'Getting address...')
                                          : (_fullAddress.isNotEmpty 
                                              ? _fullAddress 
                                              : _addressText),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (_isGeocodingLoading)
                                    Padding(
                                      padding: EdgeInsets.only(left: 8.w),
                                      child: SizedBox(
                                        width: 16.w,
                                        height: 16.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    const Divider(),
                    SizedBox(height: 16.h),

                    // معلومات إضافية
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.gps_fixed,
                            label: 'address.accuracy'.tr(),
                            value: '${_accuracy.toStringAsFixed(1)} m',
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.access_time,
                            label: 'address.last_update'.tr(),
                            value: _lastUpdated != null
                                ? DateFormat('HH:mm:ss').format(_lastUpdated!)
                                : '--:--:--',
                          ),
                        ),
                      ],
                    ),

                    // ✅ زر إعادة تحديد العنوان
                    if (_currentLocation != null && !_isGeocodingLoading) ...[
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _getAddressFromCoordinates(
                            _currentLocation!.latitude,
                            _currentLocation!.longitude,
                          ),
                          icon: Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                          label: Text(
                            context.locale.languageCode == 'ar' 
                                ? 'إعادة تحديد العنوان' 
                                : 'Refresh Address',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // زر حفظ الموقع
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveLocationToFirebase,
                        icon: _isSaving
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload,
                                color: AppColors.white),
                        label: Text(
                          _isSaving
                              ? 'address.saving'.tr()
                              : 'address.save_location'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// عنصر معلومات
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
