import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/firestore/doctor_service.dart';
import '../../../services/firestore/specialty_service.dart';
import '../model/doctor_model.dart';
import '../model/specialty_model.dart';
import 'doctors_state.dart';

class DoctorsCubit extends Cubit<DoctorsState> {
  final DoctorService _doctorService = DoctorService();
  final SpecialtyService _specialtyService = SpecialtyService();

  List<DoctorModel> _allDoctors = [];
  List<SpecialtyModel> _specialties = [];
  List<DoctorModel> _popularDoctors = [];
  String? _selectedSpecialty;
  String _searchQuery = '';

  DoctorsCubit() : super(DoctorsInitial());

  // Load all data
  Future<void> loadData() async {
    emit(DoctorsLoading());

    try {
      // Load specialties
      _specialties = await _specialtyService.getSpecialties();

      // Load all doctors
      _allDoctors = await _doctorService.getDoctors();

      // Load popular doctors
      _popularDoctors = await _doctorService.getTopDoctors(limit: 5);

      _emitLoaded();
    } catch (e) {
      emit(DoctorsError(message: e.toString()));
    }
  }

  // Load only for home (popular + specialties)
  Future<void> loadHomeData() async {
    emit(DoctorsLoading());

    try {
      // Load specialties
      _specialties = await _specialtyService.getSpecialties();

      // Load popular doctors
      _popularDoctors = await _doctorService.getTopDoctors(limit: 5);

      emit(DoctorsLoaded(
        doctors: [],
        filteredDoctors: [],
        specialties: _specialties,
        popularDoctors: _popularDoctors,
        selectedSpecialty: null,
        searchQuery: '',
        allDoctors: _allDoctors,
        searchResults: const [],
      ));
    } catch (e) {
      emit(DoctorsError(message: e.toString()));
    }
  }

  // Load doctors list (loads ALL data for client-side filtering)
  Future<void> loadDoctorsList({String? specialtyFilter}) async {
    emit(DoctorsLoading());

    try {
      // 1. Load Specialties
      try {
        _specialties = await _specialtyService.getSpecialties();
      } catch (e) {
        print('⚠️ Failed to load specialties: $e');
        // Continue...
      }

      // 2. Load ALL Doctors (Always load all for client-side filtering)
      _allDoctors = await _doctorService.getDoctors();
      print('👨‍⚕️ Loaded ${_allDoctors.length} doctors');

      // 3. Apply Initial Filter if provided
      if (specialtyFilter != null &&
          specialtyFilter.isNotEmpty &&
          specialtyFilter != 'All') {
        _selectedSpecialty = specialtyFilter;
        _emitLoaded(); // This will filter based on _selectedSpecialty
      } else {
        _selectedSpecialty = 'All'; // Default to 'All'
        _emitLoaded();
      }
    } catch (e) {
      print('❌ Error in loadDoctorsList: $e');
      emit(DoctorsError(message: e.toString()));
    }
  }

  // Filter by specialty (Local Filter)
  void filterBySpecialty(String? specialtyEn) {
    _selectedSpecialty = specialtyEn ?? 'All';
    _emitLoaded();
  }

  // Search doctors (Local Search)
  void searchDoctors(String query, String lang) {
    _searchQuery = query;
    _emitLoaded();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _emitLoaded();
  }

  // Internal helper to filter and emit
  void _emitLoaded() {
    List<DoctorModel> filtered = List.from(_allDoctors);

    // 1. Apply Specialty Filter
    if (_selectedSpecialty != null &&
        _selectedSpecialty != 'All' &&
        _selectedSpecialty!.isNotEmpty) {
      filtered = filtered.where((doc) {
        // Check both English and Arabic just in case, or just English key
        return doc.specialty['en'] == _selectedSpecialty;
      }).toList();
    }

    // 2. Apply Search Filter
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filtered = filtered.where((doc) {
        final name = doc.getName('en').toLowerCase() +
            ' ' +
            doc.getName('ar').toLowerCase();
        final specialty = doc.getSpecialty('en').toLowerCase() +
            ' ' +
            doc.getSpecialty('ar').toLowerCase();
        return name.contains(lowerQuery) || specialty.contains(lowerQuery);
      }).toList();
    }

    // 3. Apply Search to Specialties (Unified Search)
    List<SpecialtyModel> filteredSpecs = [];
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filteredSpecs = _specialties.where((s) {
        return s.getName('en').toLowerCase().contains(lowerQuery) ||
            s.getName('ar').toLowerCase().contains(lowerQuery);
      }).toList();
    }

    emit(DoctorsLoaded(
      doctors: _allDoctors,
      filteredDoctors: filtered,
      specialties: _specialties,
      filteredSpecialties: filteredSpecs, // ✅ Pass filtered specialties
      popularDoctors: _popularDoctors,
      selectedSpecialty: _selectedSpecialty,
      searchQuery: _searchQuery,
      allDoctors: _allDoctors,
      searchResults: const [],
    ));
  }

  // ============================================
  // Search for Home Screen
  // ============================================
  void searchDoctorsHome(String query) {
    // ... code for home search (can likely reuse searchDoctors logic if refactored, but keeping separate for now if needed)
    searchDoctors(query, 'en'); // Reusing the main logic for simplicty
  }

  // Add points to doctor
  Future<void> addPointsToDoctor(String doctorId, int points) async {
    await _doctorService.addPoints(doctorId, points);
  }

  // Refresh data
  Future<void> refresh() async {
    await loadDoctorsList(specialtyFilter: _selectedSpecialty);
  }
}
