import 'package:cloud_firestore/cloud_firestore.dart';

class GroceryProductModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final String categoryId;
  final String unit;
  final double unitValue;
  final bool isAvailable;
  final int stockQuantity;
  final double rating;
  final int reviewsCount;
  final DateTime? createdAt;

  GroceryProductModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    required this.categoryId,
    required this.unit,
    required this.unitValue,
    this.isAvailable = true,
    this.stockQuantity = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.createdAt,
  });

  /// Get localized name
  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  /// Get localized description
  String getDescription(String lang) => lang == 'ar' ? descriptionAr : descriptionEn;

  /// Check if has discount
  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  /// Calculate discount percentage
  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  /// Check if in stock
  bool get isInStock => isAvailable && stockQuantity > 0;

  /// Get formatted price
  String get formattedPrice => '${price.toStringAsFixed(2)}';

  /// Get formatted old price
  String get formattedOldPrice =>
      oldPrice != null ? '${oldPrice!.toStringAsFixed(2)}' : '';

  /// Get unit display text
  String getUnitDisplay(String lang) {
    final units = {
      'kg': lang == 'ar' ? 'كجم' : 'kg',
      'g': lang == 'ar' ? 'جم' : 'g',
      'piece': lang == 'ar' ? 'قطعة' : 'piece',
      'pack': lang == 'ar' ? 'عبوة' : 'pack',
      'bottle': lang == 'ar' ? 'زجاجة' : 'bottle',
      'can': lang == 'ar' ? 'علبة' : 'can',
      'liter': lang == 'ar' ? 'لتر' : 'L',
      'ml': lang == 'ar' ? 'مل' : 'ml',
    };

    final unitText = units[unit] ?? unit;

    if (unitValue == 1) {
      return unitText;
    } else if (unitValue < 1) {
      // For values like 0.5 kg or 250g
      if (unit == 'kg' && unitValue < 1) {
        return '${(unitValue * 1000).toInt()} ${units['g']}';
      }
      return '$unitValue $unitText';
    } else {
      return '${unitValue.toInt()} $unitText';
    }
  }

  factory GroceryProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroceryProductModel(
      id: doc.id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      descriptionAr: data['descriptionAr'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      oldPrice: data['oldPrice'] != null ? (data['oldPrice']).toDouble() : null,
      imageUrl: data['imageUrl'] ?? '',
      categoryId: data['categoryId'] ?? '',
      unit: data['unit'] ?? 'piece',
      unitValue: (data['unitValue'] ?? 1).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      stockQuantity: data['stockQuantity'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'price': price,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'unit': unit,
      'unitValue': unitValue,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  GroceryProductModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    double? price,
    double? oldPrice,
    String? imageUrl,
    String? categoryId,
    String? unit,
    double? unitValue,
    bool? isAvailable,
    int? stockQuantity,
    double? rating,
    int? reviewsCount,
    DateTime? createdAt,
  }) {
    return GroceryProductModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      unitValue: unitValue ?? this.unitValue,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'GroceryProductModel(id: $id, nameEn: $nameEn, price: $price)';
}
