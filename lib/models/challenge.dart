import 'package:cloud_firestore/cloud_firestore.dart';

class YearData {
  final int year;
  final double baseline;
  final double policy1;
  final double policy2;
  final double policy3;

  YearData({
    required this.year,
    required this.baseline,
    required this.policy1,
    required this.policy2,
    required this.policy3,
  });

  factory YearData.fromMap(Map<String, dynamic> map) {
    return YearData(
      year: map['year'] as int? ?? 0,
      baseline: (map['baseline'] as num?)?.toDouble() ?? 0.0,
      policy1: (map['policy1'] as num?)?.toDouble() ?? 0.0,
      policy2: (map['policy2'] as num?)?.toDouble() ?? 0.0,
      policy3: (map['policy3'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'year': year,
    'baseline': baseline,
    'policy1': policy1,
    'policy2': policy2,
    'policy3': policy3,
  };
}

class Challenge {
  final String id;
  final String name;
  final String description;
  final List<YearData> graphData;
  final String unit;
  final String supervisedBy;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.graphData,
    required this.unit,
    required this.supervisedBy,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final graphDataList = (data['graphData'] as List?)
        ?.cast<Map<String, dynamic>>()
        .map((item) => YearData.fromMap(item))
        .toList() ?? [];

    return Challenge(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      graphData: graphDataList,
      unit: data['unit'] as String? ?? '',
      supervisedBy: data['supervisedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'graphData': graphData.map((item) => item.toMap()).toList(),
    'unit': unit,
    'supervisedBy': supervisedBy,
  };
}
