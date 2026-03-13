import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String id;
  final String visitorId;
  final String doctorId;
  final Map<String, String> doctorName;
  final Map<String, String> specialty;
  final DateTime addedAt;

  FavoriteModel({
    required this.id,
    required this.visitorId,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.addedAt,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map, String docId) {
    return FavoriteModel(
      id: docId,
      visitorId: map['visitorId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName:
          Map<String, String>.from(map['doctorName'] ?? {'en': '', 'ar': ''}),
      specialty:
          Map<String, String>.from(map['specialty'] ?? {'en': '', 'ar': ''}),
      addedAt: _parseDateTime(map['addedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  // Get localized values
  String getDoctorName(String lang) =>
      doctorName[lang] ?? doctorName['en'] ?? '';
  String getSpecialty(String lang) => specialty[lang] ?? specialty['en'] ?? '';

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
