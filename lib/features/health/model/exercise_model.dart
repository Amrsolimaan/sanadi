import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع التمرين
enum ExerciseType { breathing, stretching, meditation, yoga }

/// نموذج التمرين
class ExerciseModel {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final int durationSeconds;
  final String imageUrl;
  final int order;
  final ExerciseType type;
  final Map<String, String>? instructions;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationSeconds,
    required this.imageUrl,
    required this.order,
    required this.type,
    this.instructions,
  });

  factory ExerciseModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExerciseModel(
      id: docId,
      name: Map<String, String>.from(map['name'] ?? {'en': '', 'ar': ''}),
      description: Map<String, String>.from(map['description'] ?? {'en': '', 'ar': ''}),
      durationSeconds: map['durationSeconds'] ?? 30,
      imageUrl: map['imageUrl'] ?? '',
      order: map['order'] ?? 0,
      type: _parseType(map['type']),
      instructions: map['instructions'] != null
          ? Map<String, String>.from(map['instructions'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'durationSeconds': durationSeconds,
      'imageUrl': imageUrl,
      'order': order,
      'type': type.name,
      'instructions': instructions,
    };
  }

  // Getters للغة
  String getName(String lang) => name[lang] ?? name['en'] ?? '';
  String getDescription(String lang) => description[lang] ?? description['en'] ?? '';
  String? getInstructions(String lang) => instructions?[lang] ?? instructions?['en'];

  // المدة منسقة
  String getFormattedDuration() {
    if (durationSeconds < 60) {
      return '${durationSeconds}s';
    }
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (seconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  static ExerciseType _parseType(String? type) {
    switch (type) {
      case 'breathing':
        return ExerciseType.breathing;
      case 'stretching':
        return ExerciseType.stretching;
      case 'meditation':
        return ExerciseType.meditation;
      case 'yoga':
        return ExerciseType.yoga;
      default:
        return ExerciseType.stretching;
    }
  }
}

/// تمرين التنفس - مراحل الدورة
enum BreathingPhase { breatheIn, hold, breatheOut, holdAfterOut }

/// إعدادات تمرين التنفس
class BreathingExerciseConfig {
  final int breatheInSeconds;
  final int holdSeconds;
  final int breatheOutSeconds;
  final int holdAfterOutSeconds;
  final int totalDurationMinutes;

  const BreathingExerciseConfig({
    this.breatheInSeconds = 4,
    this.holdSeconds = 4,
    this.breatheOutSeconds = 4,
    this.holdAfterOutSeconds = 0,
    this.totalDurationMinutes = 5,
  });

  int get cycleSeconds => breatheInSeconds + holdSeconds + breatheOutSeconds + holdAfterOutSeconds;
  int get totalCycles => (totalDurationMinutes * 60) ~/ cycleSeconds;
}
