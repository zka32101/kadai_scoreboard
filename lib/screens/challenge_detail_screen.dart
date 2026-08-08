import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadai_scoreboard/models/challenge.dart';
import 'package:kadai_scoreboard/providers/auth_provider.dart';
import 'package:kadai_scoreboard/providers/firestore_provider.dart';
import 'package:kadai_scoreboard/providers/impact_provider.dart';
import 'package:kadai_scoreboard/providers/paywall_provider.dart';
import 'package:kadai_scoreboard/providers/user_provider.dart';
import 'package:kadai_scoreboard/widgets/policy_comparison_chart.dart';
import 'package:kadai_scoreboard/widgets/policy_time_machine_slider.dart';
import 'package:kadai_scoreboard/widgets/personal_impact_card.dart';
import 'package:kadai_scoreboard/widgets/share_button.dart';
import 'paywall_screen.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const ChallengeDetailScreen({
    super.key,
    required this.challengeId,
  });

  @override
  ConsumerState<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  final GlobalKey _shareBoundaryKey = GlobalKey();
  bool _viewCounted = false;
  bool _paywallChecked = false;

  void _countViewOnce() {
    if (_viewCounted) return;
    _viewCounted = true;
    final userId = ref.read(userUidProvider);
    if (userId != null) {
      incrementGraphViewCount(ref.read(firebaseFirestoreProvider), userId);
    }
  }

  Future<void> _maybeShowPaywallOnce() async {
    if (_paywallChecked) return;
    _paywallChecked = true;
    if (ref.read(shouldShowPaywallProvider)) {
      await Future.microtask(() {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeProvider(widget.challengeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('課題詳細'),
        centerTitle: true,
      ),
      body: challengeAsync.when(
        data: (challenge) {
          if (challenge == null) {
            return const Center(child: Text('課題が見つかりません'));
          }
          _countViewOnce();
          _maybeShowPaywallOnce();
          return _buildChallengeDetail(context, ref, challenge);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }

  Widget _buildChallengeDetail(BuildContext context, WidgetRef ref, Challenge challenge) {
    final selectedPolicy = ref.watch(selectedPolicyProvider(challenge.id));
    final impact = ref.watch(personalImpactProvider(challenge));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Description
          Text(
            challenge.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Supervised By (信頼性明記)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '監修',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.supervisedBy,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Graph Data Table
          Text(
            'データ (単位: ${challenge.unit})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildDataTable(challenge),
          const SizedBox(height: 32),

          // Policy comparison graph (dynamically highlights selected policy)
          Text(
            '政策比較グラフ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          PolicyComparisonChart(
            challenge: challenge,
            selectedPolicy: selectedPolicy,
          ),
          const SizedBox(height: 16),

          // Time machine slider — drives both charts above/below
          PolicyTimeMachineSlider(
            value: selectedPolicy,
            onChanged: (policy) {
              ref.read(selectedPolicyProvider(challenge.id).notifier).state = policy;
            },
          ),
          const SizedBox(height: 32),

          // Personal impact (Aha Moment) — wrapped for screenshot sharing
          RepaintBoundary(
            key: _shareBoundaryKey,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'あなたのマイ人生インパクト',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  PersonalImpactCard(challenge: challenge, impact: impact),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ShareButton(
            boundaryKey: _shareBoundaryKey,
            challenge: challenge,
            selectedPolicy: selectedPolicy,
            impact: impact,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(Challenge challenge) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(),
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[200]),
            children: [
              _buildTableCell('年', bold: true),
              _buildTableCell('現状維持', bold: true),
              _buildTableCell('与党案', bold: true),
              _buildTableCell('野党案', bold: true),
              _buildTableCell('専門家案', bold: true),
            ],
          ),
          // Data rows
          ...challenge.graphData.take(5).map((data) => TableRow(
            children: [
              _buildTableCell(data.year.toString()),
              _buildTableCell(data.baseline.toStringAsFixed(1)),
              _buildTableCell(data.policy1.toStringAsFixed(1)),
              _buildTableCell(data.policy2.toStringAsFixed(1)),
              _buildTableCell(data.policy3.toStringAsFixed(1)),
            ],
          )),
          if (challenge.graphData.length > 5)
            TableRow(
              children: List.filled(
                5,
                _buildTableCell('...'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
