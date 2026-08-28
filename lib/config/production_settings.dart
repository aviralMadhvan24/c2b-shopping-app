class ProductionSettings {
  const ProductionSettings._();

  static const appTitle = 'Niyati Mart';
  static const brandName = 'Niyati Mart';

  static const checkoutMode = CheckoutMode.guestAllowed;
  static const authMethods = [AuthMethod.google];
  static const productBackend = ProductBackend.firebase;
  static const paymentPreference =
      PaymentPreference.cashOnDelivery;
  static const targetPlatform = TargetPlatformPlan.androidFirst;

  static const wishlistRequired = true;
  static const savedAddressesRequiredForLoggedInUsers = true;
  static const orderHistoryRequiredForLoggedInUsers = true;
  static const pushNotificationsRequired = true;
  static const discountsManagedInApp = true;
  static const returnsManagedInApp = true;
}

enum CheckoutMode { guestAllowed, loginRequired }

enum AuthMethod { emailPassword, google, phoneOtp }

enum ProductBackend { firebase }

enum PaymentPreference { cashOnDelivery }

enum TargetPlatformPlan { androidFirst, androidIos, allPlatforms }
