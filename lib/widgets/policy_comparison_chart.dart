import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kadai_scoreboard/models/challenge.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';

/// Multi-line comparison of all four policy trajectories (population-level
/// figures, not personalized). The line matching [selectedPolicy] is drawn
/// bold and in the theme color; the rest are dimmed for context.
class PolicyComparisonChart extends StatelessWidget {
  final Challenge challenge;
  final PolicyType selectedPolicy;

  const PolicyComparisonChart({
    super.key,
    required this.challenge,
    required this.selectedPolicy,
  });

  static const _policyLabels = {
    PolicyType.baseline: '現状維持',
    PolicyType.policy1: '与党案',
    PolicyType.policy2: '野党案',
    PolicyType.policy3: '専門家案',
  };

  static const _policyColors = {
    PolicyType.baseline: Colors.grey,
    PolicyType.policy1: Colors.red,
    PolicyType.policy2: Colors.blue,
    PolicyType.policy3: Colors.green,
  };

  double _valueFor(YearData y, PolicyType p) {
    switch (p) {
      case PolicyType.baseline:
        return y.baseline;
      case PolicyType.policy1:
        return y.policy1;
      case PolicyType.policy2:
        return y.policy2;
      case PolicyType.policy3:
        return y.policy3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (challenge.graphData.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    final data = challenge.graphData;
    final firstYear = data.first.year;

    final lines = PolicyType.values.map((policy) {
      final isSelected = policy == selectedPolicy;
      final spots = data
          .map((y) => FlSpot(
                (y.year - firstYear).toDouble(),
                _valueFor(y, policy),
              ))
          .toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: _policyColors[policy]!.withValues(alpha: isSelected ? 1.0 : 0.3),
        barWidth: isSelected ? 3.5 : 1.5,
        dotData: const FlDotData(show: false),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              lineBarsData: lines,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final year = firstYear + value.toInt();
                      if (!data.any((d) => d.year == year)) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('$year', style: const TextStyle(fontSize: 10)),
                      );
                    },
                    interval: data.length > 6 ? (data.length / 5).ceilToDouble() : 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: PolicyType.values.map((policy) {
            final isSelected = policy == selectedPolicy;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _policyColors[policy]!.withValues(alpha: isSelected ? 1.0 : 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _policyLabels[policy]!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
