class ProductionSettings {
  const ProductionSettings._();

  static const appTitle = 'Fashion Store';
  static const brandName = 'FashionHub';

  static const checkoutMode = CheckoutMode.guestAllowed;
  static const authMethods = [AuthMethod.emailPassword, AuthMethod.google];
  static const productBackend = ProductBackend.shopify;
  static const paymentPreference =
      PaymentPreference.shopifyPaymentsThenRazorpay;
  static const targetPlatform = TargetPlatformPlan.androidFirst;

  static const wishlistRequired = true;
  static const savedAddressesRequiredForLoggedInUsers = true;
  static const orderHistoryRequiredForLoggedInUsers = true;
  static const pushNotificationsRequired = true;
  static const discountsManagedByShopify = true;
  static const returnsManagedByShopifyAdmin = true;
}

enum CheckoutMode { guestAllowed, loginRequired }

enum AuthMethod { emailPassword, google, phoneOtp }

enum ProductBackend { shopify }

enum PaymentPreference { shopifyPaymentsThenRazorpay }

enum TargetPlatformPlan { androidFirst, androidIos, allPlatforms }
