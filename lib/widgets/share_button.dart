import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadai_scoreboard/models/challenge.dart';
import 'package:kadai_scoreboard/providers/auth_provider.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';
import 'package:kadai_scoreboard/services/share_service.dart';

class ShareButton extends ConsumerStatefulWidget {
  final GlobalKey boundaryKey;
  final Challenge challenge;
  final PolicyType selectedPolicy;
  final List<YearlyImpact> impact;

  const ShareButton({
    super.key,
    required this.boundaryKey,
    required this.challenge,
    required this.selectedPolicy,
    required this.impact,
  });

  @override
  ConsumerState<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends ConsumerState<ShareButton> {
  bool _isSharing = false;

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    try {
      await ShareService.shareImpact(
        boundaryKey: widget.boundaryKey,
        challenge: widget.challenge,
        selectedPolicy: widget.selectedPolicy,
        impact: widget.impact,
        userId: ref.read(userUidProvider),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('シェアに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSharing ? null : _handleShare,
        icon: _isSharing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.share),
        label: Text(_isSharing ? 'シェア中...' : '結果をシェアする'),
      ),
    );
  }
}
