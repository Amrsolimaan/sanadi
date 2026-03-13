import 'package:equatable/equatable.dart';
import '../model/doctor_model.dart';
import '../model/specialty_model.dart';

abstract class DoctorsState extends Equatable {
  const DoctorsState();

  @override
  List<Object?> get props => [];
}

// Initial
class DoctorsInitial extends DoctorsState {}

// Loading
class DoctorsLoading extends DoctorsState {}

// Loaded
class DoctorsLoaded extends DoctorsState {
  final List<DoctorModel> doctors;
  final List<DoctorModel> filteredDoctors;
  final List<SpecialtyModel> specialties;
  final List<DoctorModel> popularDoctors;
  final String? selectedSpecialty;
  final String searchQuery;

  // ✅ إضافة جديدة للـ Home Screen
  final List<DoctorModel> allDoctors;
  final List<DoctorModel> searchResults;

  final List<SpecialtyModel> filteredSpecialties; // ✅ For Unified Search

  const DoctorsLoaded({
    required this.doctors,
    required this.filteredDoctors,
    required this.specialties,
    this.filteredSpecialties = const [], // ✅ Initialize
    required this.popularDoctors,
    this.selectedSpecialty,
    this.searchQuery = '',
    this.allDoctors = const [],
    this.searchResults = const [],
  });

  @override
  List<Object?> get props => [
        doctors,
        filteredDoctors,
        specialties,
        filteredSpecialties, // ✅ Add to props
        popularDoctors,
        selectedSpecialty,
        searchQuery,
        allDoctors,
        searchResults,
      ];
}

// Empty
class DoctorsEmpty extends DoctorsState {}

// Error
class DoctorsError extends DoctorsState {
  final String message;

  const DoctorsError({required this.message});

  @override
  List<Object?> get props => [message];
}
