import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final int age;
  final String occupation;
  final String region;
  final DateTime createdAt;
  final bool isPremium;
  final int graphViewCount;

  User({
    required this.uid,
    required this.age,
    required this.occupation,
    required this.region,
    required this.createdAt,
    this.isPremium = false,
    this.graphViewCount = 0,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      age: data['age'] as int? ?? 0,
      occupation: data['occupation'] as String? ?? '',
      region: data['region'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPremium: data['isPremium'] as bool? ?? false,
      graphViewCount: data['graphViewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'age': age,
    'occupation': occupation,
    'region': region,
    'createdAt': Timestamp.fromDate(createdAt),
    'isPremium': isPremium,
    'graphViewCount': graphViewCount,
  };

  User copyWith({
    String? uid,
    int? age,
    String? occupation,
    String? region,
    DateTime? createdAt,
    bool? isPremium,
    int? graphViewCount,
  }) {
    return User(
      uid: uid ?? this.uid,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
      graphViewCount: graphViewCount ?? this.graphViewCount,
    );
  }
}
