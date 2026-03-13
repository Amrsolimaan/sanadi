import 'package:cloud_firestore/cloud_firestore.dart';

// ========================================
// User Role Enum - إضافة جديدة
// ========================================
enum UserRole {
  user,
  moderator,
  admin,
  superAdmin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
    }
  }

  String getDisplayName(String lang) {
    if (lang == 'ar') {
      switch (this) {
        case UserRole.user:
          return 'مستخدم';
        case UserRole.moderator:
          return 'مشرف';
        case UserRole.admin:
          return 'مدير';
        case UserRole.superAdmin:
          return 'مدير عام';
      }
    } else {
      switch (this) {
        case UserRole.user:
          return 'User';
        case UserRole.moderator:
          return 'Moderator';
        case UserRole.admin:
          return 'Admin';
        case UserRole.superAdmin:
          return 'Super Admin';
      }
    }
  }

  static UserRole fromString(String? value) {
    switch (value) {
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.user;
    }
  }
}

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? primaryContactId;
  final UserLocation? location;

  // Rules Fields
  final UserRole role;
  final bool isActive;
  final String? createdBy;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
    this.primaryContactId,
    this.location,
    this.role = UserRole.user,
    this.isActive = true,
    this.createdBy,
  });

  // ========================================
  // Permission Getters - تم تصحيح المنطق
  // ========================================
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isModerator => role == UserRole.moderator;

  // صلاحية الوصول للداشبورد - فقط المشرف والمدير والمدير العام
  bool get hasAdminAccess =>
      role == UserRole.moderator ||
      role == UserRole.admin ||
      role == UserRole.superAdmin;

  bool canView() => hasAdminAccess;
  bool canAdd() => role == UserRole.admin || role == UserRole.superAdmin;
  bool canEdit() => role == UserRole.admin || role == UserRole.superAdmin;
  bool canDelete() => role == UserRole.admin || role == UserRole.superAdmin;
  bool canManageUsers() => role == UserRole.superAdmin;
  bool canManageAdmins() => role == UserRole.superAdmin;
  bool canExportData() => role == UserRole.admin || role == UserRole.superAdmin;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      primaryContactId: map['primaryContactId'],
      profileImage: map['profileImage'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      location: map['location'] != null
          ? UserLocation.fromMap(map['location'] as Map<String, dynamic>)
          : null,
      role: UserRoleExtension.fromString(map['role']),
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'primaryContactId': primaryContactId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (location != null) 'location': location!.toMap(),
      'role': role.value,
      'isActive': isActive,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    Object? profileImage = const _Undefined(),
    String? primaryContactId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? location = const _Undefined(),
    UserRole? role,
    bool? isActive,
    String? createdBy,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage == const _Undefined()
          ? this.profileImage
          : profileImage as String?,
      primaryContactId: primaryContactId ?? this.primaryContactId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      location: location == const _Undefined()
          ? this.location
          : location as UserLocation?,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

// ============================================
// Location Model
// ============================================
class UserLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? updatedAt;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.updatedAt,
  });

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.now())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? updatedAt,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get googleMapsUrl =>
      'https://www.google.com/maps?q=$latitude,$longitude';

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  @override
  String toString() => 'UserLocation($latitude, $longitude)';
}

class _Undefined {
  const _Undefined();
}
