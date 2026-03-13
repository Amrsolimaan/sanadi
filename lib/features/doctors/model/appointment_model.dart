import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { upcoming, completed, cancelled }

class AppointmentModel {
  final String id;
  final String? patientName;
  final String? patientPhone;
  final String visitorId; // المستخدم الذي حجز
  final String doctorId;
  final Map<String, String> doctorName;
  final String? doctorImage; // ✅ صورة الطبيب
  final Map<String, String> specialty;
  final String date; // "2024-07-10"
  final String time; // "11:30"
  final AppointmentStatus status;
  final DateTime createdAt;
  final String? notes;

  AppointmentModel({
    required this.id,
    this.patientName,
    this.patientPhone,
    required this.visitorId,
    required this.doctorId,
    required this.doctorName,
    this.doctorImage,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return AppointmentModel(
      id: docId,
      patientName: map['patientName'],
      patientPhone: map['patientPhone'],
      visitorId: map['visitorId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName:
          Map<String, String>.from(map['doctorName'] ?? {'en': '', 'ar': ''}),
      doctorImage: map['doctorImage'],
      specialty:
          Map<String, String>.from(map['specialty'] ?? {'en': '', 'ar': ''}),
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      status: _parseStatus(map['status']),
      createdAt: _parseDateTime(map['createdAt']),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'patientPhone': patientPhone,
      'visitorId': visitorId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorImage': doctorImage,
      'specialty': specialty,
      'date': date,
      'time': time,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  // Get localized values
  String getDoctorName(String lang) =>
      doctorName[lang] ?? doctorName['en'] ?? '';
  String getSpecialty(String lang) => specialty[lang] ?? specialty['en'] ?? '';

  // Parse status
  static AppointmentStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.upcoming;
    }
  }

  // Parse datetime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  // Copy with
  AppointmentModel copyWith({
    String? id,
    String? patientName,
    String? patientPhone,
    String? visitorId,
    String? doctorId,
    Map<String, String>? doctorName,
    Map<String, String>? specialty,
    String? date,
    String? time,
    AppointmentStatus? status,
    DateTime? createdAt,
    String? notes,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      visitorId: visitorId ?? this.visitorId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  // Format date for display
  String getFormattedDate() {
    try {
      final parts = date.split('-');
      final months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[int.parse(parts[1])]} ${parts[2]}, ${parts[0]}';
    } catch (e) {
      return date;
    }
  }

  // Format time for display
  String getFormattedTime() {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } catch (e) {
      return time;
    }
  }
}
