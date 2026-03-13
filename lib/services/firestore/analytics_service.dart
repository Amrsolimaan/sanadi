import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/model/user_model.dart';
import '../../features/doctors/model/doctor_model.dart';
import '../../features/grocery/model/cart_item_model.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 1. Top Doctors
  /// Rank by: Rating (primary), Reviews Count (secondary)
  Future<List<DoctorModel>> getTopDoctors({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('doctors')
          .orderBy('rating', descending: true)
          .orderBy('reviewsCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching top doctors: $e');
      return [];
    }
  }

  /// 2. Most Active Users
  /// Currently fetching users and sorting manually (since simple 'activity' field might not exist).
  /// For scalable solution: We should have an 'ordersCount' or 'activityScore' field on UserModel.
  /// For now, we will assume we can sort by 'lastLoginAt' or 'createdAt' as a proxy, 
  /// OR better: fetch users and check valid "orders" collection count if possible.
  /// Given the current UserModel, we will sort by recent activity (updatedAt).
  Future<List<UserModel>> getMostActiveUsers({int limit = 5}) async {
    try {
      // Ideal: orderBy('ordersCount', descending: true)
      final snapshot = await _firestore
          .collection('users')
          .orderBy('updatedAt', descending: true) 
          .where('role', isEqualTo: 'user')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching active users: $e');
      return [];
    }
  }

  /// 3. Interest Trends - Doctors (Most Favorited)
  /// Uses Collection Group Query on 'favorites'
  Future<List<Map<String, dynamic>>> getTopFavoritedDoctors({int limit = 5}) async {
    try {
      // NOTE: This requires an Index on 'favorites' collection group: {doctorId: ASC/DESC}
      final snapshot = await _firestore.collectionGroup('favorites').get();

      // Count occurrences manually (for small-medium datasets)
      // For large datasets, use Distributed Counters or aggregation queries.
      final Map<String, int> doctorCounts = {};
      final Map<String, String> doctorNames = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final doctorId = data['doctorId'] as String?;
        final doctorName = data['doctorName'] as Map<String, dynamic>?;

        if (doctorId != null) {
          doctorCounts[doctorId] = (doctorCounts[doctorId] ?? 0) + 1;
          if (doctorNames[doctorId] == null && doctorName != null) {
             // Try to get English name
             doctorNames[doctorId] = doctorName['en'] ?? doctorName['ar'] ?? 'Unknown';
          }
        }
      }

      final sortedKeys = doctorCounts.keys.toList()
        ..sort((k1, k2) => doctorCounts[k2]!.compareTo(doctorCounts[k1]!));

      return sortedKeys.take(limit).map((id) {
        return {
          'id': id,
          'name': doctorNames[id] ?? 'Unknown Doctor',
          'count': doctorCounts[id],
          'type': 'Doctor'
        };
      }).toList();

    } catch (e) {
      print('Error fetching top favorited doctors: $e');
      return [];
    }
  }

  /// 4. Interest Trends - Products (Most Added to Cart)
  /// Uses Collection Group Query on 'cart'
  Future<List<Map<String, dynamic>>> getTopCartProducts({int limit = 5}) async {
    try {
      final snapshot = await _firestore.collectionGroup('cart').get();

      final Map<String, int> productCounts = {};
      final Map<String, String> productNames = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;
        final nameEn = data['nameEn'] as String?;

        if (productId != null) {
          // You might sum 'quantity' instead of just counting occurences
          final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
          productCounts[productId] = (productCounts[productId] ?? 0) + quantity;
          
          if (productNames[productId] == null && nameEn != null) {
            productNames[productId] = nameEn;
          }
        }
      }

      final sortedKeys = productCounts.keys.toList()
        ..sort((k1, k2) => productCounts[k2]!.compareTo(productCounts[k1]!));

      return sortedKeys.take(limit).map((id) {
        return {
          'id': id,
          'name': productNames[id] ?? 'Unknown Product',
          'count': productCounts[id],
          'type': 'Product'
        };
      }).toList();

    } catch (e) {
      print('Error fetching top cart products: $e');
      return [];
    }
  }
}
