import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sanadi/core/utils/phone_number_helper.dart';
import '../../../services/location/location_service.dart';
import '../../../services/firestore/user_service.dart';
import '../../../services/firestore/emergency_contact_service.dart';
import '../../emergency/model/emergency_contact_model.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  final EmergencyContactService _contactService = EmergencyContactService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LocationData? _currentLocationData;
  String? _userName;
  EmergencyContactModel? _primaryContact;
  List<EmergencyContactModel> _allContacts = [];

  LocationCubit() : super(LocationInitial());

  String? get _userId => _auth.currentUser?.uid;

  // Getters
  LocationData? get currentLocationData => _currentLocationData;
  String? get userName => _userName;
  EmergencyContactModel? get primaryContact => _primaryContact;
  List<EmergencyContactModel> get allContacts => _allContacts;

  // تحميل البيانات
  Future<void> loadLocationData() async {
    if (_userId == null) {
      emit(const LocationError(
        message: 'User not logged in',
        type: LocationErrorType.unknown,
      ));
      return;
    }

    emit(LocationLoading());

    try {
      // 1. تحقق من خدمة الموقع
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationError(
          message: 'location.service_disabled',
          type: LocationErrorType.serviceDisabled,
        ));
        return;
      }

      // 2. تحقق من الإذن
      LocationPermission permission = await _locationService.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(const LocationError(
            message: 'location.permission_denied',
            type: LocationErrorType.permissionDenied,
          ));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(const LocationError(
          message: 'location.permission_denied_forever',
          type: LocationErrorType.permissionDeniedForever,
        ));
        return;
      }

      // 3. احصل على الموقع
      final locationData = await _locationService.getLocationData();
      if (locationData == null) {
        emit(const LocationError(
          message: 'location.failed_to_get',
          type: LocationErrorType.timeout,
        ));
        return;
      }
      _currentLocationData = locationData;

      // 4. احصل على اسم المستخدم
      final user = await _userService.getUser(_userId!);
      _userName = user?.fullName ?? 'Unknown';

      // 5. احصل على جهات الاتصال
      _allContacts = await _contactService.getContacts(_userId!);

      // 6. احصل على جهة الاتصال الأساسية
      final primaryContactId =
          await _contactService.getPrimaryContactId(_userId!);
      _primaryContact = null;

      if (primaryContactId != null && primaryContactId.isNotEmpty) {
        for (var contact in _allContacts) {
          if (contact.id == primaryContactId) {
            _primaryContact = contact;
            break;
          }
        }
      }

      emit(LocationLoaded(
        locationData: locationData,
        primaryContactName: _primaryContact?.name,
        primaryContactPhone: _primaryContact?.phone,
        hasPrimaryContact: _primaryContact != null,
        totalContacts: _allContacts.length,
      ));
    } catch (e) {
      emit(LocationError(
        message: e.toString(),
        type: LocationErrorType.unknown,
      ));
    }
  }

  // تحديث الموقع
  Future<void> refreshLocation() async {
    await loadLocationData();
  }

  // إرسال للجهة الأساسية عبر WhatsApp
  Future<void> sendToPrimaryContact(String language) async {
    if (_primaryContact == null) {
      emit(const LocationError(
        message: 'location.no_primary_contact',
        type: LocationErrorType.noPrimaryContact,
      ));
      // Restore state
      if (_currentLocationData != null) {
        emit(LocationLoaded(
          locationData: _currentLocationData!,
          primaryContactName: null,
          primaryContactPhone: null,
          hasPrimaryContact: false,
          totalContacts: _allContacts.length,
        ));
      }
      return;
    }

    if (_currentLocationData == null) {
      emit(const LocationError(
        message: 'location.no_data',
        type: LocationErrorType.unknown,
      ));
      return;
    }

    emit(LocationSending());

    try {
      final message = _locationService.createWhatsAppMessage(
        senderName: _userName ?? 'Unknown',
        locationData: _currentLocationData!,
        language: language,
      );

      // 👇 تنسيق رقم الهاتف قبل الإرسال
      final formattedPhone = PhoneNumberHelper.formatEgyptianPhone(
        _primaryContact!.phone,
      );

      final success = await _locationService.sendViaWhatsApp(
        phoneNumber: formattedPhone,
        message: message,
      );

      if (success) {
        emit(LocationSent(contactName: _primaryContact!.name));
      } else {
        emit(const LocationSendFailed(message: 'location.whatsapp_failed'));
      }

      // Restore loaded state
      await Future.delayed(const Duration(seconds: 1));
      emit(LocationLoaded(
        locationData: _currentLocationData!,
        primaryContactName: _primaryContact?.name,
        primaryContactPhone: _primaryContact?.phone,
        hasPrimaryContact: _primaryContact != null,
        totalContacts: _allContacts.length,
      ));
    } catch (e) {
      emit(LocationSendFailed(message: e.toString()));
    }
  }

  // مشاركة مع الجميع
  Future<void> shareWithAll(String language) async {
    if (_currentLocationData == null) {
      emit(const LocationError(
        message: 'location.no_data',
        type: LocationErrorType.unknown,
      ));
      return;
    }

    try {
      final message = _locationService.createWhatsAppMessage(
        senderName: _userName ?? 'Unknown',
        locationData: _currentLocationData!,
        language: language,
      );

      await _locationService.shareWithAll(message: message);
    } catch (e) {
      emit(LocationSendFailed(message: e.toString()));
    }
  }

  // فتح إعدادات الموقع
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  // فتح إعدادات التطبيق
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }
}
