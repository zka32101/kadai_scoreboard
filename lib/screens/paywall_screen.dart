import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:kadai_scoreboard/services/analytics_service.dart';
import 'package:kadai_scoreboard/services/purchase_service.dart';

/// Soft paywall shown once the free view threshold is crossed. Dismissible —
/// the design doc targets a 2% free-to-paid conversion, not a hard gate.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  bool _isLoadingOffering = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    final offering = await PurchaseService.getCurrentOffering();
    if (mounted) {
      setState(() {
        _offering = offering;
        _isLoadingOffering = false;
      });
    }
  }

  Future<void> _handlePurchase(Package package) async {
    setState(() => _isPurchasing = true);
    try {
      final unlocked = await PurchaseService.purchase(package);
      if (unlocked) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'isPremium': true});
        }
        await AnalyticsService.logPurchasedPremium(
          productId: package.storeProduct.identifier,
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('購入に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packages = _offering?.availablePackages ?? const <Package>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('プレミアムプラン'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.workspace_premium, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'もっと課題を自分ごと化しよう',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'プレミアムプランでは、すべての課題のマイ人生インパクトを無制限に確認できます。',
            ),
            const SizedBox(height: 32),
            if (_isLoadingOffering)
              const Center(child: CircularProgressIndicator())
            else if (packages.isEmpty)
              const Text('現在プランを取得できません。しばらくしてから再度お試しください。')
            else
              ...packages.map((package) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPurchasing ? null : () => _handlePurchase(package),
                        child: Text(
                          '${package.storeProduct.priceString} ではじめる',
                        ),
                      ),
                    ),
                  )),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isPurchasing ? null : () => Navigator.of(context).pop(false),
                child: const Text('後で'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
