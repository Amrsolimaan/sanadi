import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryCategoryModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String image;
  final String color;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  GroceryCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.image,
    required this.color,
    required this.order,
    this.isActive = true,
    this.createdAt,
  });

  /// Get localized name
  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  /// Parse color from hex string
  int get colorValue {
    try {
      return int.parse(color.replaceFirst('0x', ''), radix: 16);
    } catch (e) {
      return 0xFF4CAF50; // Default green
    }
  }

  factory GroceryCategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroceryCategoryModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      image: data['image'] ?? '',
      color: data['color'] ?? '0xFF4CAF50',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'image': image,
      'color': color,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  GroceryCategoryModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? image,
    String? color,
    int? order,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GroceryCategoryModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      image: image ?? this.image,
      color: color ?? this.color,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'GroceryCategoryModel(id: $id, nameEn: $nameEn)';
}
