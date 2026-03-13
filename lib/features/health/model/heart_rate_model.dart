import 'package:cloud_firestore/cloud_firestore.dart';

/// تصنيف ضربات القلب
enum HeartRateCategory { low, normal, high }

/// سجل قياس ضربات القلب
class HeartRateModel {
  final String id;
  final String visitorId;
  final int bpm; // ضربات في الدقيقة
  final HeartRateCategory category;
  final DateTime measuredAt;
  final String? notes;

  HeartRateModel({
    required this.id,
    required this.visitorId,
    required this.bpm,
    required this.category,
    required this.measuredAt,
    this.notes,
  });

  factory HeartRateModel.fromMap(Map<String, dynamic> map, String docId) {
    final bpm = map['bpm'] ?? 0;
    return HeartRateModel(
      id: docId,
      visitorId: map['visitorId'] ?? '',
      bpm: bpm,
      category: _categorize(bpm),
      measuredAt: _parseDateTime(map['measuredAt']),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visitorId': visitorId,
      'bpm': bpm,
      'category': category.name,
      'measuredAt': Timestamp.fromDate(measuredAt),
      'notes': notes,
    };
  }

  /// تصنيف BPM
  static HeartRateCategory _categorize(int bpm) {
    if (bpm < 60) return HeartRateCategory.low;
    if (bpm > 100) return HeartRateCategory.high;
    return HeartRateCategory.normal;
  }

  /// تصنيف من BPM
  static HeartRateCategory categorizeFromBpm(int bpm) {
    return _categorize(bpm);
  }

  /// اسم التصنيف
  String getCategoryLabel(String lang) {
    final labels = {
      'en': {
        HeartRateCategory.low: 'Low',
        HeartRateCategory.normal: 'Normal',
        HeartRateCategory.high: 'High',
      },
      'ar': {
        HeartRateCategory.low: 'منخفض',
        HeartRateCategory.normal: 'طبيعي',
        HeartRateCategory.high: 'مرتفع',
      },
    };
    return labels[lang]?[category] ?? labels['en']![category]!;
  }

  /// لون التصنيف
  static int getCategoryColorValue(HeartRateCategory category) {
    switch (category) {
      case HeartRateCategory.low:
        return 0xFFFFC107; // أصفر
      case HeartRateCategory.normal:
        return 0xFF4CAF50; // أخضر
      case HeartRateCategory.high:
        return 0xFFF44336; // أحمر
    }
  }

  /// أيقونة التصنيف
  static String getCategoryIcon(HeartRateCategory category) {
    switch (category) {
      case HeartRateCategory.low:
        return '⬇️';
      case HeartRateCategory.normal:
        return '✅';
      case HeartRateCategory.high:
        return '⬆️';
    }
  }

  /// التاريخ منسق
  String getFormattedDate() {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[measuredAt.month]} ${measuredAt.day}, ${measuredAt.year}';
  }

  /// الوقت منسق
  String getFormattedTime() {
    final hour = measuredAt.hour;
    final minute = measuredAt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
