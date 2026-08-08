import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kadai_scoreboard/models/user.dart' as user_model;
import 'package:kadai_scoreboard/services/analytics_service.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int? selectedAge;
  String? selectedOccupation;
  String? selectedRegion;
  bool isLoading = false;

  final occupations = [
    '会社員',
    '公務員',
    '自営業',
    '学生',
    '無職',
    'その他',
  ];

  final regions = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県',
  ];

  Future<void> _saveUserProfile() async {
    if (selectedAge == null || selectedOccupation == null || selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を選択してください')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final user = user_model.User(
          uid: currentUser.uid,
          age: selectedAge!,
          occupation: selectedOccupation!,
          region: selectedRegion!,
          createdAt: DateTime.now(),
          isPremium: false,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(user.toFirestore());

        await AnalyticsService.logAgeInputComplete(
          age: selectedAge!,
          occupation: selectedOccupation!,
          region: selectedRegion!,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール設定'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'あなたについて教えてください',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),

            // Age Selector
            Text(
              '年齢',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButton<int>(
              isExpanded: true,
              value: selectedAge,
              hint: const Text('年齢を選択'),
              items: List.generate(
                101,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text('$i歳'),
                ),
              ),
              onChanged: (value) => setState(() => selectedAge = value),
            ),
            const SizedBox(height: 32),

            // Occupation Selector
            Text(
              '職業',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedOccupation,
              hint: const Text('職業を選択'),
              items: occupations
                  .map((occ) => DropdownMenuItem(
                        value: occ,
                        child: Text(occ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedOccupation = value),
            ),
            const SizedBox(height: 32),

            // Region Selector
            Text(
              '都道府県',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedRegion,
              hint: const Text('都道府県を選択'),
              items: regions
                  .map((region) => DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedRegion = value),
            ),
            const SizedBox(height: 48),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveUserProfile,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('次へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
