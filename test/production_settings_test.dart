import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/config/production_settings.dart';

void main() {
  test('production settings match the selected Phase 1 decisions', () {
    expect(ProductionSettings.appTitle, 'Fashion Store');
    expect(ProductionSettings.brandName, 'FashionHub');
    expect(ProductionSettings.checkoutMode, CheckoutMode.guestAllowed);
    expect(
      ProductionSettings.authMethods,
      containsAll([AuthMethod.emailPassword, AuthMethod.google]),
    );
    expect(ProductionSettings.productBackend, ProductBackend.shopify);
    expect(
      ProductionSettings.paymentPreference,
      PaymentPreference.shopifyPaymentsThenRazorpay,
    );
    expect(ProductionSettings.targetPlatform, TargetPlatformPlan.androidFirst);

    expect(ProductionSettings.wishlistRequired, isTrue);
    expect(ProductionSettings.savedAddressesRequiredForLoggedInUsers, isTrue);
    expect(ProductionSettings.orderHistoryRequiredForLoggedInUsers, isTrue);
    expect(ProductionSettings.pushNotificationsRequired, isTrue);
    expect(ProductionSettings.discountsManagedByShopify, isTrue);
    expect(ProductionSettings.returnsManagedByShopifyAdmin, isTrue);
  });
}
