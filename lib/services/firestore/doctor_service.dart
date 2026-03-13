import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/doctors/model/doctor_model.dart';

// Pagination result class
class PaginatedDoctors {
  final List<DoctorModel> doctors;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedDoctors({
    required this.doctors,
    this.lastDocument,
    required this.hasMore,
  });
}

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collection = 'doctor';

  // Get doctors with pagination - improved version
  Future<PaginatedDoctors> getDoctorsPaginated({
    int limit = 5,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection(_collection).limit(limit + 1); // +1 للتحقق من وجود المزيد
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      bool hasMore = docs.length > limit;
      final doctorsToReturn = hasMore ? docs.take(limit).toList() : docs;

      final doctors = doctorsToReturn
          .map((doc) => DoctorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return PaginatedDoctors(
        doctors: doctors,
        lastDocument: doctorsToReturn.isNotEmpty ? doctorsToReturn.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      print('Error loading doctors: $e');
      throw Exception('Failed to load doctors: $e');
    }
  }

  // Get doctors with pagination
  Future<List<DoctorModel>> getDoctors({
    int limit = 5,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection(_collection).limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final doctors = snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return doctors;
    } catch (e) {
      print('Error loading doctors: $e');
      throw Exception('Failed to load doctors: $e');
    }
  }

  // Get all doctors (للاستخدام في البحث فقط)
  Future<List<DoctorModel>> getAllDoctors() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final doctors = snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();

      // ترتيب محلي
      doctors
          .sort((a, b) => (a.name['en'] ?? '').compareTo(b.name['en'] ?? ''));

      return doctors;
    } catch (e) {
      print('Error loading doctors: $e');
      throw Exception('Failed to load doctors: $e');
    }
  }

  // Get doctors by specialty with pagination - improved version
  Future<PaginatedDoctors> getDoctorsBySpecialtyPaginated(
    String specialtyEn, {
    int limit = 5,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('specialty.en', isEqualTo: specialtyEn)
          .limit(limit + 1); // +1 للتحقق من وجود المزيد
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;

      bool hasMore = docs.length > limit;
      final doctorsToReturn = hasMore ? docs.take(limit).toList() : docs;

      final doctors = doctorsToReturn
          .map((doc) => DoctorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return PaginatedDoctors(
        doctors: doctors,
        lastDocument: doctorsToReturn.isNotEmpty ? doctorsToReturn.last : null,
        hasMore: hasMore,
      );
    } catch (e) {
      print('Error loading doctors by specialty: $e');
      throw Exception('Failed to load doctors: $e');
    }
  }

  // Get top doctors by points (for Popular section)
  Future<List<DoctorModel>> getTopDoctors({int limit = 5}) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();

      final doctors = snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();

      // ترتيب محلي حسب النقاط (الأعلى أولاً)
      doctors.sort((a, b) => (b.points).compareTo(a.points));

      return doctors.take(limit).toList();
    } catch (e) {
      print('Error loading top doctors: $e');
      throw Exception('Failed to load top doctors: $e');
    }
  }

  // Get doctor by ID
  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return DoctorModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error loading doctor: $e');
      throw Exception('Failed to load doctor: $e');
    }
  }

  // Add points to doctor
  Future<void> addPoints(String doctorId, int points) async {
    try {
      await _firestore.collection(_collection).doc(doctorId).update({
        'points': FieldValue.increment(points),
      });
    } catch (e) {
      print('Failed to add points: $e');
    }
  }

  // Search doctors with pagination (يستخدم getAllDoctors للبحث المحلي)
  Future<List<DoctorModel>> searchDoctorsAsync(String query, String lang) async {
    if (query.isEmpty) return [];

    try {
      final allDoctors = await getAllDoctors();
      return searchDoctors(allDoctors, query, lang);
    } catch (e) {
      print('Error searching doctors: $e');
      throw Exception('Failed to search doctors: $e');
    }
  }

  // Search doctors
  List<DoctorModel> searchDoctors(
      List<DoctorModel> doctors, String query, String lang) {
    if (query.isEmpty) return doctors;

    final lowerQuery = query.toLowerCase();
    return doctors.where((doctor) {
      return doctor.getName(lang).toLowerCase().contains(lowerQuery) ||
          doctor.getSpecialty(lang).toLowerCase().contains(lowerQuery) ||
          doctor.getBio(lang).toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
