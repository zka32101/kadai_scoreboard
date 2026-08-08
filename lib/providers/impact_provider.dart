import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadai_scoreboard/models/challenge.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';
import 'package:kadai_scoreboard/providers/user_provider.dart';

final selectedPolicyProvider =
    StateProvider.family<PolicyType, String>((ref, challengeId) => PolicyType.baseline);

Map<String, double> _yearValues(YearData y) => {
  'baseline': y.baseline,
  'policy1': y.policy1,
  'policy2': y.policy2,
  'policy3': y.policy3,
};

final personalImpactProvider =
    Provider.family<List<YearlyImpact>, Challenge>((ref, challenge) {
  final userProfile = ref.watch(userProfileProvider).valueOrNull;
  final selectedPolicy = ref.watch(selectedPolicyProvider(challenge.id));

  if (userProfile == null) return [];

  return ImpactCalculator.calculate<YearData>(
    graphData: challenge.graphData,
    yearValueExtractor: _yearValues,
    yearExtractor: (y) => y.year,
    selectedPolicy: selectedPolicy,
    userAge: userProfile.age,
    occupation: userProfile.occupation,
    region: userProfile.region,
    currentYear: DateTime.now().year,
  );
});
