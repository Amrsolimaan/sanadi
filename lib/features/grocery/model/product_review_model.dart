import 'package:cloud_firestore/cloud_firestore.dart';

class ProductReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int rating;
  final String? comment;
  final String? orderId;
  final bool isVerifiedPurchase;
  final DateTime? createdAt;

  ProductReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    this.comment,
    this.orderId,
    this.isVerifiedPurchase = true,
    this.createdAt,
  });

  /// Get formatted date
  String get formattedDate {
    if (createdAt == null) return '';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  /// Get time ago text
  String getTimeAgo(String lang) {
    if (createdAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return lang == 'ar' ? 'منذ $months شهر' : '$months months ago';
    } else if (difference.inDays > 0) {
      return lang == 'ar' ? 'منذ ${difference.inDays} يوم' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return lang == 'ar' ? 'منذ ${difference.inHours} ساعة' : '${difference.inHours} hours ago';
    } else {
      return lang == 'ar' ? 'منذ قليل' : 'Just now';
    }
  }

  factory ProductReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhoto: data['userPhoto'],
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      orderId: data['orderId'],
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      'orderId': orderId,
      'isVerifiedPurchase': isVerifiedPurchase,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ProductReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userPhoto,
    int? rating,
    String? comment,
    String? orderId,
    bool? isVerifiedPurchase,
    DateTime? createdAt,
  }) {
    return ProductReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      orderId: orderId ?? this.orderId,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ProductReviewModel(id: $id, productId: $productId, rating: $rating)';
}
