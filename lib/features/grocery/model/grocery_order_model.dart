import 'package:cloud_firestore/cloud_firestore.dart';

/// Order Status Enum
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String getDisplayName(String lang) {
    if (lang == 'ar') {
      switch (this) {
        case OrderStatus.pending:
          return 'قيد الانتظار';
        case OrderStatus.confirmed:
          return 'تم التأكيد';
        case OrderStatus.preparing:
          return 'جاري التجهيز';
        case OrderStatus.onTheWay:
          return 'في الطريق';
        case OrderStatus.delivered:
          return 'تم التوصيل';
        case OrderStatus.cancelled:
          return 'ملغي';
      }
    } else {
      switch (this) {
        case OrderStatus.pending:
          return 'Pending';
        case OrderStatus.confirmed:
          return 'Confirmed';
        case OrderStatus.preparing:
          return 'Preparing';
        case OrderStatus.onTheWay:
          return 'On the way';
        case OrderStatus.delivered:
          return 'Delivered';
        case OrderStatus.cancelled:
          return 'Cancelled';
      }
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Order Item Model
class OrderItemModel {
  final String productId;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final int quantity;
  final double price;
  final String unit;
  final double total;
  final bool isReviewed;

  OrderItemModel({
    required this.productId,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    required this.unit,
    required this.total,
    this.isReviewed = false,
  });

  String getName(String lang) => lang == 'ar' ? nameAr : nameEn;

  factory OrderItemModel.fromMap(Map<String, dynamic> data) {
    return OrderItemModel(
      productId: data['productId'] ?? '',
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'piece',
      total: (data['total'] ?? 0).toDouble(),
      isReviewed: data['isReviewed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'total': total,
      'isReviewed': isReviewed,
    };
  }

  OrderItemModel copyWith({
    String? productId,
    String? nameAr,
    String? nameEn,
    String? imageUrl,
    int? quantity,
    double? price,
    String? unit,
    double? total,
    bool? isReviewed,
  }) {
    return OrderItemModel(
      productId: productId ?? this.productId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      total: total ?? this.total,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}

/// Order Model
class GroceryOrderModel {
  final String id;
  final String orderNumber;
  final String uid;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItemModel> items;
  final double subtotal;
  final double totalAmount;
  final OrderStatus status;
  final String? notes;
  final bool whatsappSent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GroceryOrderModel({
    required this.id,
    required this.orderNumber,
    required this.uid,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.notes,
    this.whatsappSent = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Get formatted date
  String get formattedDate {
    if (createdAt == null) return '';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  /// Get items count
  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Check if can be cancelled
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  /// Check if is active order
  bool get isActive =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  factory GroceryOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroceryOrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      uid: data['uid'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromMap(item))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: OrderStatusExtension.fromString(data['status'] ?? 'pending'),
      notes: data['notes'],
      whatsappSent: data['whatsappSent'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'uid': uid,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'totalAmount': totalAmount,
      'status': status.value,
      'notes': notes,
      'whatsappSent': whatsappSent,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  GroceryOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? uid,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItemModel>? items,
    double? subtotal,
    double? totalAmount,
    OrderStatus? status,
    String? notes,
    bool? whatsappSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      uid: uid ?? this.uid,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      whatsappSent: whatsappSent ?? this.whatsappSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generate WhatsApp message
  String generateWhatsAppMessage(String lang) {
    final buffer = StringBuffer();

    buffer.writeln(
        '🛒 *${lang == 'ar' ? 'طلب جديد - سندي' : 'New Order - Sanadi'}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    buffer.writeln(
        '📋 *${lang == 'ar' ? 'رقم الطلب:' : 'Order #:'}* $orderNumber');
    buffer.writeln(
        '👤 *${lang == 'ar' ? 'العميل:' : 'Customer:'}* $customerName');
    buffer
        .writeln('📞 *${lang == 'ar' ? 'الهاتف:' : 'Phone:'}* $customerPhone');
    buffer.writeln(
        '📍 *${lang == 'ar' ? 'العنوان:' : 'Address:'}* $deliveryAddress');
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📦 *${lang == 'ar' ? 'المنتجات:' : 'Products:'}*');
    buffer.writeln();

    for (var item in items) {
      final name = item.getName(lang);
      buffer.writeln(
          '• $name (${item.quantity} ${item.unit}) - ${item.total.toStringAsFixed(2)} ${lang == 'ar' ? 'ج' : 'EGP'}');
    }

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '💰 ${lang == 'ar' ? 'المجموع:' : 'Subtotal:'} ${subtotal.toStringAsFixed(2)} ${lang == 'ar' ? 'ج' : 'EGP'}');
    buffer.writeln(
        '✅ *${lang == 'ar' ? 'الإجمالي:' : 'Total:'} ${totalAmount.toStringAsFixed(2)} ${lang == 'ar' ? 'ج' : 'EGP'}*');

    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 *${lang == 'ar' ? 'ملاحظات:' : 'Notes:'}* $notes');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━');

    return buffer.toString();
  }

  @override
  String toString() =>
      'GroceryOrderModel(id: $id, orderNumber: $orderNumber, status: ${status.value})';
}
