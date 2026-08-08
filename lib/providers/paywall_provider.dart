import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kadai_scoreboard/providers/user_provider.dart';
import 'package:kadai_scoreboard/services/remote_config_service.dart';

final isPremiumProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.maybeWhen(
    data: (user) => user?.isPremium ?? false,
    orElse: () => false,
  );
});

/// True once the free user has crossed the Remote Config-driven view
/// threshold (design doc default: "グラフ閲覧5回後"). Premium users never
/// see the paywall regardless of count.
final shouldShowPaywallProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  if (isPremium) return false;

  final userProfile = ref.watch(userProfileProvider);
  final viewCount = userProfile.maybeWhen(
    data: (user) => user?.graphViewCount ?? 0,
    orElse: () => 0,
  );

  return viewCount >= RemoteConfigService.paywallViewThreshold;
});
