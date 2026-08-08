import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kadai_scoreboard/models/challenge.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';

/// The "マイ人生インパクト" Aha Moment — shows the personalized series for
/// the currently selected policy, scoped to the user's own age/occupation/
/// region, plus a headline figure for the final projection year.
class PersonalImpactCard extends StatelessWidget {
  final Challenge challenge;
  final List<YearlyImpact> impact;

  const PersonalImpactCard({
    super.key,
    required this.challenge,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    if (impact.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('プロフィールを設定するとマイ人生インパクトが表示されます'),
      );
    }

    final last = impact.last;
    final first = impact.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'あなたが${last.userAgeAtYear}歳になる${last.year}年',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                last.value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 4),
              Text(challenge.unit, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: impact
                        .map((i) => FlSpot(
                              (i.year - first.year).toDouble(),
                              i.value,
                            ))
                        .toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withValues(alpha: 0.15),
                    ),
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
