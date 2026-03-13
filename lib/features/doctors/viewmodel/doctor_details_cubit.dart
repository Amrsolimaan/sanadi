import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/firestore/doctor_service.dart';
import '../../../services/firestore/favorite_service.dart';
import '../model/doctor_model.dart';
import 'doctor_details_state.dart';

class DoctorDetailsCubit extends Cubit<DoctorDetailsState> {
  final DoctorService _doctorService = DoctorService();
  final FavoriteService _favoriteService = FavoriteService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DoctorModel? _doctor;
  bool _isFavorite = false;

  DoctorDetailsCubit() : super(DoctorDetailsInitial());

  String? get _userId => _auth.currentUser?.uid;
  DoctorModel? get doctor => _doctor;
  bool get isFavorite => _isFavorite;

  // Load doctor details
  Future<void> loadDoctor(DoctorModel doctor) async {
    emit(DoctorDetailsLoading());

    try {
      _doctor = doctor;

      // Check if favorite
      if (_userId != null) {
        _isFavorite = await _favoriteService.isFavorite(_userId!, doctor.id);
      }

      emit(DoctorDetailsLoaded(
        doctor: _doctor!,
        isFavorite: _isFavorite,
      ));
    } catch (e) {
      emit(DoctorDetailsError(message: e.toString()));
    }
  }

  // Load doctor by ID
  Future<void> loadDoctorById(String doctorId) async {
    emit(DoctorDetailsLoading());

    try {
      _doctor = await _doctorService.getDoctorById(doctorId);

      if (_doctor == null) {
        emit(const DoctorDetailsError(message: 'Doctor not found'));
        return;
      }

      // Check if favorite
      if (_userId != null) {
        _isFavorite = await _favoriteService.isFavorite(_userId!, doctorId);
      }

      emit(DoctorDetailsLoaded(
        doctor: _doctor!,
        isFavorite: _isFavorite,
      ));
    } catch (e) {
      emit(DoctorDetailsError(message: e.toString()));
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite() async {
    if (_userId == null || _doctor == null) return;

    try {
      _isFavorite = await _favoriteService.toggleFavorite(
        userId: _userId!,
        doctor: _doctor!,
      );

      emit(FavoriteToggled(isFavorite: _isFavorite));

      // Re-emit loaded state
      emit(DoctorDetailsLoaded(
        doctor: _doctor!,
        isFavorite: _isFavorite,
      ));
    } catch (e) {
      // Silently fail
      print('Failed to toggle favorite: $e');
    }
  }

  // Call doctor
  Future<void> callDoctor() async {
    if (_doctor == null) return;

    try {
      final phoneUrl = Uri.parse('tel:${_doctor!.phone}');
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
        // Add points
        await _doctorService.addPoints(_doctor!.id, 5);
      }
    } catch (e) {
      print('Failed to call: $e');
    }
  }

  // WhatsApp doctor
  Future<void> whatsAppDoctor() async {
    if (_doctor == null) return;

    try {
      // Clean phone number
      String phone = _doctor!.phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (!phone.startsWith('+')) {
        phone = '+$phone';
      }
      // Remove the + for wa.me
      phone = phone.replaceAll('+', '');

      final whatsappUrl = Uri.parse('https://wa.me/$phone');
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        // Add points
        await _doctorService.addPoints(_doctor!.id, 3);
      }
    } catch (e) {
      print('Failed to open WhatsApp: $e');
    }
  }

  // Reset
  void reset() {
    _doctor = null;
    _isFavorite = false;
    emit(DoctorDetailsInitial());
  }
}
