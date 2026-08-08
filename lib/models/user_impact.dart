import 'package:cloud_firestore/cloud_firestore.dart';

class UserImpact {
  final String id;
  final String userId;
  final String challengeId;
  final String selectedPolicy;
  final Map<int, double> result;
  final DateTime createdAt;
  final int shareCount;

  UserImpact({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.selectedPolicy,
    required this.result,
    required this.createdAt,
    this.shareCount = 0,
  });

  factory UserImpact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<int, double> result = {};
    if (data['result'] is Map) {
      (data['result'] as Map).forEach((key, value) {
        final year = int.tryParse(key.toString());
        final value_ = (value as num?)?.toDouble();
        if (year != null && value_ != null) {
          result[year] = value_;
        }
      });
    }

    return UserImpact(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      challengeId: data['challengeId'] as String? ?? '',
      selectedPolicy: data['selectedPolicy'] as String? ?? '',
      result: result,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shareCount: data['shareCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'challengeId': challengeId,
    'selectedPolicy': selectedPolicy,
    // Firestore maps require String keys; fromFirestore parses them back to int.
    'result': result.map((year, value) => MapEntry(year.toString(), value)),
    'createdAt': Timestamp.fromDate(createdAt),
    'shareCount': shareCount,
  };

  UserImpact incrementShare() {
    return UserImpact(
      id: id,
      userId: userId,
      challengeId: challengeId,
      selectedPolicy: selectedPolicy,
      result: result,
      createdAt: createdAt,
      shareCount: shareCount + 1,
    );
  }
}
