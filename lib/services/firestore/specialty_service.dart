import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/doctors/model/specialty_model.dart';

class SpecialtyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference (مثل grocery_service)
  CollectionReference get _specialtiesRef =>
      _firestore.collection('specialties');

  /// Get all specialties (نفس أسلوب grocery_service)
  Future<List<SpecialtyModel>> getSpecialties() async {
    try {
      debugPrint('🔍 Fetching specialties...');

      // ✅ استخدام CollectionReference مباشرة
      final snapshot = await _specialtiesRef.get();

      debugPrint('✅ Found ${snapshot.docs.length} specialties');

      // ✅ استخدام fromFirestore بدلاً من fromMap
      final specialties = snapshot.docs
          .map((doc) => SpecialtyModel.fromFirestore(doc))
          .toList();

      // Sort by order
      specialties.sort((a, b) => a.order.compareTo(b.order));

      return specialties;
    } catch (e) {
      debugPrint('❌ Error loading specialties: $e');
      return []; // ✅ return empty list instead of throw
    }
  }

  /// Get specialty by ID
  Future<SpecialtyModel?> getSpecialtyById(String id) async {
    try {
      final doc = await _specialtiesRef.doc(id).get();
      if (!doc.exists) return null;
      return SpecialtyModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting specialty: $e');
      return null;
    }
  }
}
