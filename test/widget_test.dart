import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';
import 'package:kadai_scoreboard/widgets/policy_time_machine_slider.dart';

void main() {
  testWidgets('PolicyTimeMachineSlider shows all four policy labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PolicyTimeMachineSlider(
            value: PolicyType.baseline,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('現状維持'), findsWidgets);
    expect(find.text('与党案'), findsOneWidget);
    expect(find.text('野党案'), findsOneWidget);
    expect(find.text('専門家案'), findsOneWidget);
  });

  testWidgets('dragging the slider reports the newly selected policy', (tester) async {
    PolicyType? reported;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PolicyTimeMachineSlider(
            value: PolicyType.baseline,
            onChanged: (policy) => reported = policy,
          ),
        ),
      ),
    );

    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);

    // Drag to the far right end of the track -> last policy (policy3).
    await tester.drag(sliderFinder, const Offset(500, 0));
    await tester.pump();

    expect(reported, PolicyType.policy3);
  });
}
