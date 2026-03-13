import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MedicationType { tablet, capsule, liquid, injection, drops, cream, other }

enum MedicationFrequency { daily, specificDays, asNeeded }

class MedicationModel {
  final String id;
  final String visitorId;
  final String name;
  final String? nameAr;
  final String dose;
  final MedicationType type;
  final String? purpose;
  final String? purposeAr;
  final MedicationFrequency frequency;
  final List<int> specificDays;
  final List<String> times;
  final bool isActive;
  final DateTime createdAt;

  MedicationModel({
    required this.id,
    required this.visitorId,
    required this.name,
    this.nameAr,
    required this.dose,
    required this.type,
    this.purpose,
    this.purposeAr,
    required this.frequency,
    this.specificDays = const [],
    this.times = const [],
    this.isActive = true,
    required this.createdAt,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // ✅ معالجة createdAt بشكل آمن (قد يكون Timestamp أو String أو null)
    DateTime createdAt;
    try {
      final createdAtData = data['createdAt'];
      if (createdAtData is Timestamp) {
        createdAt = createdAtData.toDate();
      } else if (createdAtData is String) {
        createdAt = DateTime.parse(createdAtData);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing createdAt for ${doc.id}: $e');
      createdAt = DateTime.now();
    }
    
    return MedicationModel(
      id: doc.id,
      visitorId: data['visitorId'] ?? '',
      name: data['name'] ?? '',
      nameAr: data['nameAr'],
      dose: data['dose'] ?? '',
      type: MedicationType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'tablet'),
        orElse: () => MedicationType.tablet,
      ),
      purpose: data['purpose'],
      purposeAr: data['purposeAr'],
      frequency: MedicationFrequency.values.firstWhere(
        (e) => e.name == (data['frequency'] ?? 'daily'),
        orElse: () => MedicationFrequency.daily,
      ),
      specificDays: List<int>.from(data['specificDays'] ?? []),
      times: List<String>.from(data['times'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'visitorId': visitorId,
      'name': name,
      'nameAr': nameAr,
      'dose': dose,
      'type': type.name,
      'purpose': purpose,
      'purposeAr': purposeAr,
      'frequency': frequency.name,
      'specificDays': specificDays,
      'times': times,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'name': name,
      'nameAr': nameAr,
      'dose': dose,
      'type': type.name, // ✅ غيرها من type إلى type.name
      'purpose': purpose,
      'purposeAr': purposeAr,
      'frequency': frequency.name, // ✅ غيرها من frequency إلى frequency.name
      'specificDays': specificDays,
      'times': times,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool shouldTakeToday() {
    if (frequency == MedicationFrequency.daily) return true;
    if (frequency == MedicationFrequency.asNeeded) return false;
    return specificDays.contains(DateTime.now().weekday);
  }

  String getName(String lang) =>
      lang == 'ar' && nameAr != null ? nameAr! : name;
  String? getPurpose(String lang) =>
      lang == 'ar' && purposeAr != null ? purposeAr : purpose;

  String getTypeLabel(String lang) {
    final labels = {
      MedicationType.tablet: lang == 'ar' ? 'أقراص' : 'Tablet',
      MedicationType.capsule: lang == 'ar' ? 'كبسولة' : 'Capsule',
      MedicationType.liquid: lang == 'ar' ? 'شراب' : 'Liquid',
      MedicationType.injection: lang == 'ar' ? 'حقنة' : 'Injection',
      MedicationType.drops: lang == 'ar' ? 'قطرة' : 'Drops',
      MedicationType.cream: lang == 'ar' ? 'كريم' : 'Cream',
      MedicationType.other: lang == 'ar' ? 'أخرى' : 'Other',
    };
    return labels[type] ?? '';
  }

  static IconData getTypeIcon(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return Icons.medication;
      case MedicationType.capsule:
        return Icons.medication_liquid;
      case MedicationType.liquid:
        return Icons.local_drink;
      case MedicationType.injection:
        return Icons.vaccines;
      case MedicationType.drops:
        return Icons.opacity;
      case MedicationType.cream:
        return Icons.soap;
      case MedicationType.other:
        return Icons.medical_services;
    }
  }
}
