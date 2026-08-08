import 'package:flutter_test/flutter_test.dart';
import 'package:kadai_scoreboard/models/challenge.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';
import 'package:kadai_scoreboard/services/share_service.dart';

void main() {
  final challenge = Challenge(
    id: 'pension',
    name: '年金',
    description: 'desc',
    graphData: const [],
    unit: '万円',
    supervisedBy: '厚生労働省年金局',
  );

  group('ShareService.buildShareText', () {
    test('falls back to a generic message when there is no headline', () {
      final text = ShareService.buildShareText(
        challenge: challenge,
        selectedPolicy: PolicyType.baseline,
        headline: null,
      );

      expect(text, contains('年金'));
      expect(text, contains('#課題スコアボード'));
    });

    test('includes personalized age, year, policy label, and value', () {
      final headline = const YearlyImpact(year: 2050, userAgeAtYear: 65, value: 12.3);

      final text = ShareService.buildShareText(
        challenge: challenge,
        selectedPolicy: PolicyType.policy2,
        headline: headline,
      );

      expect(text, contains('65歳'));
      expect(text, contains('2050年'));
      expect(text, contains('野党案'));
      expect(text, contains('12.3'));
      expect(text, contains('万円'));
    });
  });
}
