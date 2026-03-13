import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/doctors/model/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: doctor/{doctorId}/reviews
  CollectionReference _getReviewsCollection(String doctorId) {
    return _firestore.collection('doctor').doc(doctorId).collection('reviews');
  }

  // ============================================
  // Get reviews for a doctor
  // ============================================
  Future<List<ReviewModel>> getDoctorReviews(String doctorId, {int limit = 20}) async {
    try {
      final snapshot = await _getReviewsCollection(doctorId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error loading reviews: $e');
      return [];
    }
  }

  // ============================================
  // Add a review
  // ============================================
  Future<ReviewModel?> addReview({
    required String doctorId,
    required String visitorId,
    required String userName,
    String? userPhoto,
    required int rating,
    required String comment,
  }) async {
    try {
      // التحقق من عدم وجود تقييم سابق من نفس المستخدم
      final existing = await _getReviewsCollection(doctorId)
          .where('visitorId', isEqualTo: visitorId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // تحديث التقييم الموجود
        return await updateReview(
          doctorId: doctorId,
          reviewId: existing.docs.first.id,
          rating: rating,
          comment: comment,
        );
      }

      // إنشاء تقييم جديد
      final review = ReviewModel(
        id: '',
        visitorId: visitorId,
        userName: userName,
        userPhoto: userPhoto,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      final docRef = await _getReviewsCollection(doctorId).add(review.toMap());

      // تحديث إحصائيات الطبيب
      await _updateDoctorRating(doctorId);

      return ReviewModel(
        id: docRef.id,
        visitorId: visitorId,
        userName: userName,
        userPhoto: userPhoto,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  // ============================================
  // Update a review
  // ============================================
  Future<ReviewModel?> updateReview({
    required String doctorId,
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _getReviewsCollection(doctorId).doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.now(), // تحديث التاريخ
      });

      // تحديث إحصائيات الطبيب
      await _updateDoctorRating(doctorId);

      final doc = await _getReviewsCollection(doctorId).doc(reviewId).get();
      return ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error updating review: $e');
      return null;
    }
  }

  // ============================================
  // Delete a review
  // ============================================
  Future<bool> deleteReview({
    required String doctorId,
    required String reviewId,
  }) async {
    try {
      await _getReviewsCollection(doctorId).doc(reviewId).delete();

      // تحديث إحصائيات الطبيب
      await _updateDoctorRating(doctorId);

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // ============================================
  // Check if user has reviewed
  // ============================================
  Future<bool> hasUserReviewed(String doctorId, String visitorId) async {
    try {
      final snapshot = await _getReviewsCollection(doctorId)
          .where('visitorId', isEqualTo: visitorId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // Get user's review for a doctor
  // ============================================
  Future<ReviewModel?> getUserReview(String doctorId, String visitorId) async {
    try {
      final snapshot = await _getReviewsCollection(doctorId)
          .where('visitorId', isEqualTo: visitorId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ReviewModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
          snapshot.docs.first.id);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // Update doctor's rating statistics
  // ============================================
  Future<void> _updateDoctorRating(String doctorId) async {
    try {
      final reviews = await getDoctorReviews(doctorId, limit: 1000);

      if (reviews.isEmpty) {
        await _firestore.collection('doctor').doc(doctorId).update({
          'rating': 0.0,
          'reviewsCount': 0,
        });
        return;
      }

      // حساب المتوسط
      final totalRating = reviews.fold<int>(0, (sum, r) => sum + r.rating);
      final averageRating = totalRating / reviews.length;

      // تحديث الطبيب
      await _firestore.collection('doctor').doc(doctorId).update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'reviewsCount': reviews.length,
      });
    } catch (e) {
      print('Error updating doctor rating: $e');
    }
  }

  // ============================================
  // Get rating statistics
  // ============================================
  Future<Map<String, dynamic>> getRatingStats(String doctorId) async {
    try {
      final reviews = await getDoctorReviews(doctorId, limit: 1000);

      if (reviews.isEmpty) {
        return {
          'average': 0.0,
          'total': 0,
          'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      // حساب التوزيع
      final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      int totalRating = 0;

      for (var review in reviews) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
        totalRating += review.rating;
      }

      return {
        'average': totalRating / reviews.length,
        'total': reviews.length,
        'distribution': distribution,
      };
    } catch (e) {
      return {
        'average': 0.0,
        'total': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }
  }
}
