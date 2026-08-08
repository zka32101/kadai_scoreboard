import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

/// Wraps RevenueCat for the ¥120/月 premium plan.
///
/// PLACEHOLDER API key — see design doc note: paywall UX is finalized ahead
/// of RevenueCat dashboard setup, matching how `firebase_options.dart` was
/// scaffolded ahead of real Firebase credentials. Replace [_apiKey] once the
/// RevenueCat project exists.
class PurchaseService {
  PurchaseService._();

  static const String _apiKey = 'YOUR_REVENUECAT_API_KEY';
  static const String premiumEntitlementId = 'premium';

  static bool _configured = false;

  static Future<void> initialize() async {
    if (_configured) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
    } catch (_) {
      // RevenueCat not yet configured (placeholder key) — premium checks
      // fall back to "not premium" rather than crashing the app.
    }
  }

  static Future<bool> isPremium() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(premiumEntitlementId);
    } catch (_) {
      return false;
    }
  }

  static Future<Offering?> getCurrentOffering() async {
    if (!_configured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the purchase succeeded and unlocked the premium
  /// entitlement. Returns false on user cancellation; rethrows other errors
  /// so the caller can surface a message.
  static Future<bool> purchase(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      return info.entitlements.active.containsKey(premiumEntitlementId);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }
}
