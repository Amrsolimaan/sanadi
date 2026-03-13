import 'package:cloud_firestore/cloud_firestore.dart';
import 'grocery_product_model.dart';

class CartItemModel {
  final String id;
  final String productId;
  final int quantity;
  final double price;
  final DateTime? addedAt;
  
  // Optional: cached product data for display
  final String? nameAr;
  final String? nameEn;
  final String? imageUrl;
  final String? unit;
  final double? unitValue;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    this.addedAt,
    this.nameAr,
    this.nameEn,
    this.imageUrl,
    this.unit,
    this.unitValue,
  });

  /// Calculate total price for this item
  double get totalPrice => price * quantity;

  /// Get formatted total price
  String get formattedTotal => totalPrice.toStringAsFixed(2);

  /// Get localized name
  String getName(String lang) {
    if (lang == 'ar') return nameAr ?? '';
    return nameEn ?? '';
  }

  /// Get unit display
  String getUnitDisplay(String lang) {
    final units = {
      'kg': lang == 'ar' ? 'كجم' : 'kg',
      'g': lang == 'ar' ? 'جم' : 'g',
      'piece': lang == 'ar' ? 'قطعة' : 'pc',
      'pack': lang == 'ar' ? 'عبوة' : 'pack',
      'bottle': lang == 'ar' ? 'زجاجة' : 'bottle',
      'can': lang == 'ar' ? 'علبة' : 'can',
      'liter': lang == 'ar' ? 'لتر' : 'L',
      'ml': lang == 'ar' ? 'مل' : 'ml',
    };
    return units[unit] ?? unit ?? '';
  }

  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItemModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      nameAr: data['nameAr'],
      nameEn: data['nameEn'],
      imageUrl: data['imageUrl'],
      unit: data['unit'],
      unitValue: data['unitValue']?.toDouble(),
    );
  }

  factory CartItemModel.fromProduct(GroceryProductModel product, {int quantity = 1}) {
    return CartItemModel(
      id: '',
      productId: product.id,
      quantity: quantity,
      price: product.price,
      addedAt: DateTime.now(),
      nameAr: product.nameAr,
      nameEn: product.nameEn,
      imageUrl: product.imageUrl,
      unit: product.unit,
      unitValue: product.unitValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
      'addedAt': addedAt != null
          ? Timestamp.fromDate(addedAt!)
          : FieldValue.serverTimestamp(),
      'nameAr': nameAr,
      'nameEn': nameEn,
      'imageUrl': imageUrl,
      'unit': unit,
      'unitValue': unitValue,
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    int? quantity,
    double? price,
    DateTime? addedAt,
    String? nameAr,
    String? nameEn,
    String? imageUrl,
    String? unit,
    double? unitValue,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      addedAt: addedAt ?? this.addedAt,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      unitValue: unitValue ?? this.unitValue,
    );
  }

  @override
  String toString() => 'CartItemModel(productId: $productId, quantity: $quantity, total: $totalPrice)';
}
