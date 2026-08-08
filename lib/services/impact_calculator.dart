/// Personal impact calculation engine.
///
/// Converts a challenge's raw policy projections (population-level figures
/// supplied by the supervising institution) into a value scoped to a single
/// user's life — the "マイ人生インパクト" Aha Moment.
library;

enum PolicyType { baseline, policy1, policy2, policy3 }

class YearlyImpact {
  final int year;
  final int userAgeAtYear;
  final double value;

  const YearlyImpact({
    required this.year,
    required this.userAgeAtYear,
    required this.value,
  });
}

class ImpactCalculator {
  ImpactCalculator._();

  /// Occupation sensitivity coefficients.
  ///
  /// PLACEHOLDER pending supervisor sign-off (see design doc: "監修契約・
  /// データソース確定必須" before release). Keep isolated here so the real
  /// actuarial table can be swapped in without touching call sites.
  static const Map<String, double> _occupationFactor = {
    '会社員': 1.0,
    '公務員': 0.9,
    '自営業': 1.15,
    '学生': 1.3,
    '無職': 1.2,
    'その他': 1.0,
  };

  static const double _defaultOccupationFactor = 1.0;

  /// Regional cost-of-living / demographic variance coefficients.
  /// PLACEHOLDER — see note above.
  static const Map<String, double> _regionFactor = {
    '東京都': 1.1,
    '大阪府': 1.05,
    '愛知県': 1.0,
    '北海道': 0.95,
    '沖縄県': 0.9,
  };

  static const double _defaultRegionFactor = 1.0;

  static double occupationFactorFor(String occupation) =>
      _occupationFactor[occupation] ?? _defaultOccupationFactor;

  static double regionFactorFor(String region) =>
      _regionFactor[region] ?? _defaultRegionFactor;

  /// Selects the raw value for [policy] from a single year's projection map.
  /// [yearValues] must contain keys: baseline, policy1, policy2, policy3.
  static double selectPolicyValue(
    Map<String, double> yearValues,
    PolicyType policy,
  ) {
    switch (policy) {
      case PolicyType.baseline:
        return yearValues['baseline'] ?? 0.0;
      case PolicyType.policy1:
        return yearValues['policy1'] ?? 0.0;
      case PolicyType.policy2:
        return yearValues['policy2'] ?? 0.0;
      case PolicyType.policy3:
        return yearValues['policy3'] ?? 0.0;
    }
  }

  /// Weight that determines how strongly a given projection year matters to
  /// a user who will be [futureAge] years old that year. Years within a
  /// normal lifespan carry full weight; years the user won't live to see
  /// taper toward zero rather than dropping off a cliff.
  static double relevanceWeight(int futureAge) {
    const lifeExpectancy = 90;
    if (futureAge < 0) return 0.0;
    if (futureAge <= lifeExpectancy) return 1.0;
    final yearsOver = futureAge - lifeExpectancy;
    final tapered = 1.0 - (yearsOver / 10.0);
    return tapered.clamp(0.0, 1.0);
  }

  /// Computes the personalized impact series for one policy across all
  /// projection years supplied.
  ///
  /// [graphData] entries must each expose year + the four policy values as
  /// a `Map<String, double>` via [yearValueExtractor] to keep this function
  /// independent of the Firestore-backed `YearData` model (testable in
  /// isolation, no Firebase dependency).
  static List<YearlyImpact> calculate<T>({
    required List<T> graphData,
    required Map<String, double> Function(T) yearValueExtractor,
    required int Function(T) yearExtractor,
    required PolicyType selectedPolicy,
    required int userAge,
    required String occupation,
    required String region,
    required int currentYear,
  }) {
    final occFactor = occupationFactorFor(occupation);
    final regFactor = regionFactorFor(region);

    return graphData.map((entry) {
      final year = yearExtractor(entry);
      final rawValue = selectPolicyValue(yearValueExtractor(entry), selectedPolicy);
      final yearsFromNow = year - currentYear;
      final futureAge = userAge + yearsFromNow;
      final weight = relevanceWeight(futureAge);

      final personalized = rawValue * occFactor * regFactor * weight;

      return YearlyImpact(
        year: year,
        userAgeAtYear: futureAge,
        value: personalized,
      );
    }).toList();
  }
}
