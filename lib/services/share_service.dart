import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kadai_scoreboard/models/challenge.dart';
import 'package:kadai_scoreboard/providers/firestore_provider.dart' as firestore_provider;
import 'package:kadai_scoreboard/services/analytics_service.dart';
import 'package:kadai_scoreboard/services/impact_calculator.dart';

class ShareService {
  ShareService._();

  static const _policyLabels = {
    PolicyType.baseline: '現状維持',
    PolicyType.policy1: '与党案',
    PolicyType.policy2: '野党案',
    PolicyType.policy3: '専門家案',
  };

  static String buildShareText({
    required Challenge challenge,
    required PolicyType selectedPolicy,
    required YearlyImpact? headline,
  }) {
    final policyLabel = _policyLabels[selectedPolicy]!;
    if (headline == null) {
      return '「${challenge.name}」について課題スコアボードで調べてみました。#課題スコアボード';
    }
    return 'あなたが${headline.userAgeAtYear}歳になる${headline.year}年、'
        '「${challenge.name}」は$policyLabel採用で${headline.value.toStringAsFixed(1)}'
        '${challenge.unit}に。\n'
        '課題スコアボードで自分ごと化してみよう。#課題スコアボード';
  }

  /// Captures whatever is painted inside [boundaryKey] as a PNG, shares it
  /// (falling back to text-only if capture fails), records the share in
  /// Firestore, and logs the `graph_shared` KPI event.
  static Future<void> shareImpact({
    required GlobalKey boundaryKey,
    required Challenge challenge,
    required PolicyType selectedPolicy,
    required List<YearlyImpact> impact,
    required String? userId,
  }) async {
    final headline = impact.isNotEmpty ? impact.last : null;
    final text = buildShareText(
      challenge: challenge,
      selectedPolicy: selectedPolicy,
      headline: headline,
    );

    final imagePath = await _captureBoundary(boundaryKey);

    if (imagePath != null) {
      await Share.shareXFiles([XFile(imagePath)], text: text);
    } else {
      await Share.share(text);
    }

    if (userId != null) {
      await firestore_provider.recordShare(
        firestore: FirebaseFirestore.instance,
        userId: userId,
        challengeId: challenge.id,
        selectedPolicy: selectedPolicy.name,
        result: {for (final i in impact) i.year: i.value},
      );
    }

    await AnalyticsService.logGraphShared(
      challengeId: challenge.id,
      selectedPolicy: selectedPolicy.name,
    );
  }

  static Future<String?> _captureBoundary(GlobalKey boundaryKey) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/kadai_scoreboard_share_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
