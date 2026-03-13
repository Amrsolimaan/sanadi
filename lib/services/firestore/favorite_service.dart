import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/doctors/model/favorite_model.dart';
import '../../features/doctors/model/doctor_model.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: users/{userId}/favorites
  CollectionReference _getCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  // Add to favorites
  Future<FavoriteModel> addFavorite({
    required String visitorId,
    required DoctorModel doctor,
  }) async {
    try {
      // Check if already exists
      final existing = await _getCollection(visitorId)
          .where('doctorId', isEqualTo: doctor.id)
          .get();

      if (existing.docs.isNotEmpty) {
        return FavoriteModel.fromMap(
            existing.docs.first.data() as Map<String, dynamic>,
            existing.docs.first.id);
      }

      final favorite = FavoriteModel(
        id: '',
        visitorId: visitorId,
        doctorId: doctor.id,
        doctorName: doctor.name,
        specialty: doctor.specialty,
        addedAt: DateTime.now(),
      );

      final docRef = await _getCollection(visitorId).add(favorite.toMap());

      return FavoriteModel(
        id: docRef.id,
        visitorId: visitorId,
        doctorId: doctor.id,
        doctorName: doctor.name,
        specialty: doctor.specialty,
        addedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String userId, String doctorId) async {
    try {
      final snapshot = await _getCollection(userId)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  // Get user favorites
  Future<List<FavoriteModel>> getUserFavorites(String userId) async {
    try {
      final snapshot = await _getCollection(userId)
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              FavoriteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }

  // Check if doctor is favorite
  Future<bool> isFavorite(String userId, String doctorId) async {
    try {
      final snapshot = await _getCollection(userId)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite({
    required String userId,
    required DoctorModel doctor,
  }) async {
    final isFav = await isFavorite(userId, doctor.id);

    if (isFav) {
      await removeFavorite(userId, doctor.id);
      return false;
    } else {
      await addFavorite(visitorId: userId, doctor: doctor);
      return true;
    }
  }
}
