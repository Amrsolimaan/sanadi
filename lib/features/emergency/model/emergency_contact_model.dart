import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String? relationship;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContactModel.fromMap(
      Map<String, dynamic> map, String docId) {
    return EmergencyContactModel(
      id: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
