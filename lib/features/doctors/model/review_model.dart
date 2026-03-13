import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String visitorId;
  final String userName;
  final String? userPhoto;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.visitorId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      visitorId: map['visitorId'] ?? '',
      userName: map['userName'] ?? 'مستخدم',
      userPhoto: map['userPhoto'],
      rating: (map['rating'] ?? 5).toInt(),
      comment: map['comment'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  // تنسيق التاريخ للعرض
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inDays < 30) {
      return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
