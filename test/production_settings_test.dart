import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/config/production_settings.dart';

void main() {
  test('production settings match the selected Phase 1 decisions', () {
    expect(ProductionSettings.appTitle, 'Niyati Mart');
    expect(ProductionSettings.brandName, 'Niyati Mart');
    expect(ProductionSettings.checkoutMode, CheckoutMode.guestAllowed);
    expect(ProductionSettings.authMethods, [AuthMethod.google]);
    expect(ProductionSettings.productBackend, ProductBackend.firebase);
    expect(
      ProductionSettings.paymentPreference,
      PaymentPreference.cashOnDelivery,
    );
    expect(ProductionSettings.targetPlatform, TargetPlatformPlan.androidFirst);

    expect(ProductionSettings.wishlistRequired, isTrue);
    expect(ProductionSettings.savedAddressesRequiredForLoggedInUsers, isTrue);
    expect(ProductionSettings.orderHistoryRequiredForLoggedInUsers, isTrue);
    expect(ProductionSettings.pushNotificationsRequired, isTrue);
    expect(ProductionSettings.discountsManagedInApp, isTrue);
    expect(ProductionSettings.returnsManagedInApp, isTrue);
  });
}
