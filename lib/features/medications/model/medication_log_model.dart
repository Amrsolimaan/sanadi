import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicationLogStatus { taken, missed, skipped }

class MedicationLogModel {
  final String id;
  final String visitorId;
  final String medicationId;
  final String medicationName;
  final String scheduledTime;
  final DateTime? takenAt;
  final MedicationLogStatus status;
  final DateTime date;

  MedicationLogModel({
    required this.id,
    required this.visitorId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.takenAt,
    required this.status,
    required this.date,
  });

  factory MedicationLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // ✅ معالجة takenAt بشكل آمن
    DateTime? takenAt;
    if (data['takenAt'] != null) {
      try {
        final takenAtData = data['takenAt'];
        if (takenAtData is Timestamp) {
          takenAt = takenAtData.toDate();
        } else if (takenAtData is String) {
          takenAt = DateTime.parse(takenAtData);
        }
      } catch (e) {
        print('⚠️ Error parsing takenAt for ${doc.id}: $e');
      }
    }
    
    // ✅ معالجة date بشكل آمن
    DateTime date;
    try {
      final dateData = data['date'];
      if (dateData is Timestamp) {
        date = dateData.toDate();
      } else if (dateData is String) {
        date = DateTime.parse(dateData);
      } else {
        date = DateTime.now();
      }
    } catch (e) {
      print('⚠️ Error parsing date for ${doc.id}: $e');
      date = DateTime.now();
    }
    
    return MedicationLogModel(
      id: doc.id,
      visitorId: data['visitorId'] ?? '',
      medicationId: data['medicationId'] ?? '',
      medicationName: data['medicationName'] ?? '',
      scheduledTime: data['scheduledTime'] ?? '',
      takenAt: takenAt,
      status: MedicationLogStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'taken'),
        orElse: () => MedicationLogStatus.taken,
      ),
      date: date,
    );
  }
}
