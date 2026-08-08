import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Wraps Remote Config values the design doc calls out explicitly:
/// paywall timing ("グラフ閲覧5回後") and the challenge lineup (for testing
/// new challenges without a client release).
class RemoteConfigService {
  RemoteConfigService._();

  static const _paywallViewThresholdKey = 'paywall_view_threshold';
  static const int defaultPaywallViewThreshold = 5;

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults({
        _paywallViewThresholdKey: defaultPaywallViewThreshold,
      });
      await remoteConfig.fetchAndActivate();
      _initialized = true;
    } catch (_) {
      // Offline or not yet configured server-side — fall back to defaults.
    }
  }

  static int get paywallViewThreshold {
    try {
      final value = FirebaseRemoteConfig.instance.getInt(_paywallViewThresholdKey);
      return value > 0 ? value : defaultPaywallViewThreshold;
    } catch (_) {
      return defaultPaywallViewThreshold;
    }
  }
}
