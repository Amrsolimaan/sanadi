import 'package:equatable/equatable.dart';
import '../../../services/location/location_service.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

// الحالة الأولية
class LocationInitial extends LocationState {}

// جاري التحميل
class LocationLoading extends LocationState {}

// تم تحميل البيانات
class LocationLoaded extends LocationState {
  final LocationData locationData;
  final String? primaryContactName;
  final String? primaryContactPhone;
  final bool hasPrimaryContact;
  final int totalContacts;

  const LocationLoaded({
    required this.locationData,
    this.primaryContactName,
    this.primaryContactPhone,
    required this.hasPrimaryContact,
    required this.totalContacts,
  });

  @override
  List<Object?> get props => [
        locationData,
        primaryContactName,
        primaryContactPhone,
        hasPrimaryContact,
        totalContacts,
      ];
}

// خطأ
class LocationError extends LocationState {
  final String message;
  final LocationErrorType type;

  const LocationError({
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [message, type];
}

enum LocationErrorType {
  serviceDisabled, // خدمة GPS مغلقة
  permissionDenied, // رفض الإذن
  permissionDeniedForever, // رفض دائم
  timeout, // انتهاء الوقت
  noPrimaryContact, // لا يوجد جهة اتصال أساسية
  unknown, // خطأ غير معروف
}

// جاري الإرسال
class LocationSending extends LocationState {}

// تم الإرسال بنجاح
class LocationSent extends LocationState {
  final String contactName;

  const LocationSent({required this.contactName});

  @override
  List<Object?> get props => [contactName];
}

// فشل الإرسال
class LocationSendFailed extends LocationState {
  final String message;

  const LocationSendFailed({required this.message});

  @override
  List<Object?> get props => [message];
}
