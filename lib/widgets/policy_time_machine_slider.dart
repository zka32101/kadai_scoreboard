import 'package:flutter/material.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';

/// "タイムマシンスライダー" — lets the user scrub across the four policy
/// scenarios; the comparison graph and personal-impact figure below react
/// live as this changes.
class PolicyTimeMachineSlider extends StatelessWidget {
  final PolicyType value;
  final ValueChanged<PolicyType> onChanged;

  const PolicyTimeMachineSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _labels = ['現状維持', '与党案', '野党案', '専門家案'];

  @override
  Widget build(BuildContext context) {
    final index = PolicyType.values.indexOf(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'タイムマシン：政策を選んで未来を比較',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          value: index.toDouble(),
          min: 0,
          max: (PolicyType.values.length - 1).toDouble(),
          divisions: PolicyType.values.length - 1,
          label: _labels[index],
          onChanged: (v) => onChanged(PolicyType.values[v.round()]),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _labels
              .map((label) => Text(label, style: const TextStyle(fontSize: 11)))
              .toList(),
        ),
      ],
    );
  }
}
