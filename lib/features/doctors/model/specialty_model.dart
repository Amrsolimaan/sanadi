import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialtyModel {
  final String id;
  final Map<String, String> name;
  final String icon;
  final String? iconUrl;
  final int order;

  SpecialtyModel({
    required this.id,
    required this.name,
    required this.icon,
    this.iconUrl,
    required this.order,
  });

  factory SpecialtyModel.fromMap(Map<String, dynamic> map, String docId) {
    return SpecialtyModel(
      id: docId,
      name: (map['name'] is Map)
          ? Map<String, String>.from((map['name'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ))
          : {'en': 'Unknown', 'ar': 'غير معروف'},
      icon: map['icon']?.toString() ?? '',
      iconUrl: map['iconUrl']?.toString(),
      order: int.tryParse(map['order']?.toString() ?? '0') ?? 0,
    );
  }

  // ✅ إضافة fromFirestore - المهم جداً!
  factory SpecialtyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // طباعة للتأكد
    print('🔍 Reading specialty: ${doc.id}');
    print('   Raw name: ${data['name']}');
    print('   name[en]: ${data['name']?['en']}');
    print('   name[ar]: ${data['name']?['ar']}');

    return SpecialtyModel(
      id: doc.id,
      name: (data['name'] is Map)
          ? {
              'en': data['name']['en']?.toString() ?? '',
              'ar': data['name']['ar']?.toString() ?? '',
            }
          : {'en': 'Unknown', 'ar': 'غير معروف'},
      icon: data['icon']?.toString() ?? '',
      iconUrl: data['iconUrl']?.toString(),
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'iconUrl': iconUrl,
      'order': order,
    };
  }

  SpecialtyModel copyWith({
    String? id,
    Map<String, String>? name,
    String? icon,
    String? iconUrl,
    int? order,
  }) {
    return SpecialtyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconUrl: iconUrl ?? this.iconUrl,
      order: order ?? this.order,
    );
  }

  String getName(String lang) {
    final result = name[lang] ?? name['en'] ?? 'Unknown';
    print('   getName($lang) = $result');
    return result;
  }

  bool get hasImage => iconUrl != null && iconUrl!.isNotEmpty;

  @override
  String toString() =>
      'SpecialtyModel(id: $id, name: $name, icon: $icon, iconUrl: $iconUrl)';
}
