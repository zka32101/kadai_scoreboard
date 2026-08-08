import 'package:flutter_test/flutter_test.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';

class _FakeYear {
  final int year;
  final Map<String, double> values;
  _FakeYear(this.year, this.values);
}

Map<String, double> _extractValues(_FakeYear y) => y.values;
int _extractYear(_FakeYear y) => y.year;

void main() {
  group('ImpactCalculator.selectPolicyValue', () {
    final values = {
      'baseline': 100.0,
      'policy1': 80.0,
      'policy2': 60.0,
      'policy3': 40.0,
    };

    test('selects baseline', () {
      expect(
        ImpactCalculator.selectPolicyValue(values, PolicyType.baseline),
        100.0,
      );
    });

    test('selects each policy correctly', () {
      expect(ImpactCalculator.selectPolicyValue(values, PolicyType.policy1), 80.0);
      expect(ImpactCalculator.selectPolicyValue(values, PolicyType.policy2), 60.0);
      expect(ImpactCalculator.selectPolicyValue(values, PolicyType.policy3), 40.0);
    });

    test('missing key defaults to 0.0', () {
      expect(ImpactCalculator.selectPolicyValue({}, PolicyType.baseline), 0.0);
    });
  });

  group('ImpactCalculator.relevanceWeight', () {
    test('full weight within lifespan', () {
      expect(ImpactCalculator.relevanceWeight(0), 1.0);
      expect(ImpactCalculator.relevanceWeight(50), 1.0);
      expect(ImpactCalculator.relevanceWeight(90), 1.0);
    });

    test('negative future age (already passed) is zero', () {
      expect(ImpactCalculator.relevanceWeight(-5), 0.0);
    });

    test('tapers linearly past life expectancy', () {
      expect(ImpactCalculator.relevanceWeight(95), closeTo(0.5, 1e-9));
      expect(ImpactCalculator.relevanceWeight(100), 0.0);
    });

    test('never goes negative far beyond taper window', () {
      expect(ImpactCalculator.relevanceWeight(200), 0.0);
    });
  });

  group('ImpactCalculator.occupationFactorFor / regionFactorFor', () {
    test('known occupation returns its coefficient', () {
      expect(ImpactCalculator.occupationFactorFor('学生'), 1.3);
    });

    test('unknown occupation defaults to 1.0', () {
      expect(ImpactCalculator.occupationFactorFor('宇宙飛行士'), 1.0);
    });

    test('known region returns its coefficient', () {
      expect(ImpactCalculator.regionFactorFor('東京都'), 1.1);
    });

    test('unknown region defaults to 1.0', () {
      expect(ImpactCalculator.regionFactorFor('謎の県'), 1.0);
    });
  });

  group('ImpactCalculator.calculate', () {
    final graphData = [
      _FakeYear(2026, {'baseline': 100.0, 'policy1': 90.0, 'policy2': 80.0, 'policy3': 70.0}),
      _FakeYear(2030, {'baseline': 200.0, 'policy1': 180.0, 'policy2': 160.0, 'policy3': 140.0}),
      _FakeYear(2050, {'baseline': 500.0, 'policy1': 400.0, 'policy2': 300.0, 'policy3': 200.0}),
    ];

    test('applies occupation + region + relevance weighting per year', () {
      final result = ImpactCalculator.calculate<_FakeYear>(
        graphData: graphData,
        yearValueExtractor: _extractValues,
        yearExtractor: _extractYear,
        selectedPolicy: PolicyType.baseline,
        userAge: 30,
        occupation: '会社員', // factor 1.0
        region: '愛知県', // factor 1.0
        currentYear: 2026,
      );

      expect(result.length, 3);
      // 2026: age 30, weight 1.0, factors 1.0 -> 100.0
      expect(result[0].year, 2026);
      expect(result[0].userAgeAtYear, 30);
      expect(result[0].value, closeTo(100.0, 1e-9));

      // 2030: age 34, weight 1.0 -> 200.0
      expect(result[1].userAgeAtYear, 34);
      expect(result[1].value, closeTo(200.0, 1e-9));

      // 2050: age 54, weight 1.0 -> 500.0
      expect(result[2].userAgeAtYear, 54);
      expect(result[2].value, closeTo(500.0, 1e-9));
    });

    test('applies non-default occupation and region factors multiplicatively', () {
      final result = ImpactCalculator.calculate<_FakeYear>(
        graphData: [graphData[0]],
        yearValueExtractor: _extractValues,
        yearExtractor: _extractYear,
        selectedPolicy: PolicyType.baseline,
        userAge: 30,
        occupation: '学生', // 1.3
        region: '東京都', // 1.1
        currentYear: 2026,
      );

      // 100.0 * 1.3 * 1.1 * weight(1.0) = 143.0
      expect(result[0].value, closeTo(143.0, 1e-9));
    });

    test('tapers value to zero once user has aged well past life expectancy', () {
      final result = ImpactCalculator.calculate<_FakeYear>(
        graphData: [_FakeYear(2050, {'baseline': 100.0, 'policy1': 0, 'policy2': 0, 'policy3': 0})],
        yearValueExtractor: _extractValues,
        yearExtractor: _extractYear,
        selectedPolicy: PolicyType.baseline,
        userAge: 90, // futureAge = 90 + (2050-2026) = 114 -> beyond taper window
        occupation: '会社員',
        region: '愛知県',
        currentYear: 2026,
      );

      expect(result[0].value, 0.0);
    });

    test('selecting a different policy changes only the source values, not weighting', () {
      final baseline = ImpactCalculator.calculate<_FakeYear>(
        graphData: graphData,
        yearValueExtractor: _extractValues,
        yearExtractor: _extractYear,
        selectedPolicy: PolicyType.baseline,
        userAge: 30,
        occupation: '会社員',
        region: '愛知県',
        currentYear: 2026,
      );
      final policy3 = ImpactCalculator.calculate<_FakeYear>(
        graphData: graphData,
        yearValueExtractor: _extractValues,
        yearExtractor: _extractYear,
        selectedPolicy: PolicyType.policy3,
        userAge: 30,
        occupation: '会社員',
        region: '愛知県',
        currentYear: 2026,
      );

      expect(baseline[2].value, closeTo(500.0, 1e-9));
      expect(policy3[2].value, closeTo(200.0, 1e-9));
      expect(baseline[2].userAgeAtYear, policy3[2].userAgeAtYear);
    });
  });
}
