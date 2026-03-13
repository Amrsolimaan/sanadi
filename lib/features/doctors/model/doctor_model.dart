import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorLocation {
  final double latitude;
  final double longitude;
  final Map<String, String> address;

  DoctorLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory DoctorLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return DoctorLocation(
        latitude: 0,
        longitude: 0,
        address: {'en': '', 'ar': ''},
      );
    }
    return DoctorLocation(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      address: Map<String, String>.from(map['address'] ?? {'en': '', 'ar': ''}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  String getAddress(String lang) => address[lang] ?? address['en'] ?? '';

  bool get hasLocation => latitude != 0 && longitude != 0;
}

class DoctorModel {
  final String id;
  final Map<String, String> name;
  final Map<String, String> specialty;
  final Map<String, String> degree;
  final Map<String, String> bio;
  final String phone;
  final String? imageUrl;
  final double rating;
  final int reviewsCount;
  final int points;
  final bool isAvailable;
  final List<int> availableDays;
  final List<String> availableSlots;
  final DoctorLocation? location;
  final DateTime? createdAt;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.degree,
    required this.bio,
    required this.phone,
    this.imageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.points,
    required this.isAvailable,
    required this.availableDays,
    required this.availableSlots,
    this.location,
    this.createdAt,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map, String docId) {
    return DoctorModel(
      id: docId,
      name: Map<String, String>.from(map['name'] ?? {'en': '', 'ar': ''}),
      specialty:
          Map<String, String>.from(map['specialty'] ?? {'en': '', 'ar': ''}),
      degree: Map<String, String>.from(map['degree'] ?? {'en': '', 'ar': ''}),
      bio: Map<String, String>.from(map['bio'] ?? {'en': '', 'ar': ''}),
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'], //
      rating: (map['rating'] ?? 0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      points: map['points'] ?? 0,
      isAvailable: map['isAvailable'] ?? false,
      availableDays: List<int>.from(map['availableDays'] ?? []),
      availableSlots: List<String>.from(map['availableSlots'] ?? []),
      location: map['location'] != null
          ? DoctorLocation.fromMap(map['location'])
          : null, //
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'degree': degree,
      'bio': bio,
      'phone': phone,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'points': points,
      'isAvailable': isAvailable,
      'availableDays': availableDays,
      'availableSlots': availableSlots,
      'location': location?.toMap(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // Get localized values
  String getName(String lang) => name[lang] ?? name['en'] ?? '';
  String getSpecialty(String lang) => specialty[lang] ?? specialty['en'] ?? '';
  String getDegree(String lang) => degree[lang] ?? degree['en'] ?? '';
  String getBio(String lang) => bio[lang] ?? bio['en'] ?? '';
  String getAddress(String lang) => location?.getAddress(lang) ?? '';

  // Check if has location
  bool get hasLocation => location != null && location!.hasLocation;

  // Check if has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  DoctorModel copyWith({
    String? id,
    Map<String, String>? name,
    Map<String, String>? specialty,
    Map<String, String>? degree,
    Map<String, String>? bio,
    String? phone,
    String? imageUrl,
    double? rating,
    int? reviewsCount,
    int? points,
    bool? isAvailable,
    List<int>? availableDays,
    List<String>? availableSlots,
    DoctorLocation? location,
    DateTime? createdAt,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      degree: degree ?? this.degree,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      points: points ?? this.points,
      isAvailable: isAvailable ?? this.isAvailable,
      availableDays: availableDays ?? this.availableDays,
      availableSlots: availableSlots ?? this.availableSlots,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
