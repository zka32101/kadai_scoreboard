import 'package:firebase_analytics/firebase_analytics.dart';

/// Wraps the 3 KPI events the design doc deliberately limits tracking to:
/// age_input_complete (Activation), graph_shared (Referral),
/// purchased_premium (Revenue). Keep this the single place new events are
/// added so the "3 events only" constraint stays visible and enforced.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logAgeInputComplete({
    required int age,
    required String occupation,
    required String region,
  }) {
    return _analytics.logEvent(
      name: 'age_input_complete',
      parameters: {
        'age': age,
        'occupation': occupation,
        'region': region,
      },
    );
  }

  static Future<void> logGraphShared({
    required String challengeId,
    required String selectedPolicy,
  }) {
    return _analytics.logEvent(
      name: 'graph_shared',
      parameters: {
        'challenge_id': challengeId,
        'selected_policy': selectedPolicy,
      },
    );
  }

  static Future<void> logPurchasedPremium({required String productId}) {
    return _analytics.logEvent(
      name: 'purchased_premium',
      parameters: {
        'product_id': productId,
      },
    );
  }
}
