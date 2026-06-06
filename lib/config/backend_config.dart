class BackendConfig {
  const BackendConfig._();

  static const shopifyStoreDomain = String.fromEnvironment(
    'SHOPIFY_STORE_DOMAIN',
  );
  static const shopifyStorefrontAccessToken = String.fromEnvironment(
    'SHOPIFY_STOREFRONT_ACCESS_TOKEN',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static bool get hasShopifyConfig =>
      shopifyStoreDomain.isNotEmpty && shopifyStorefrontAccessToken.isNotEmpty;

  static bool get hasFirebaseProjectId => firebaseProjectId.isNotEmpty;

  static String get normalizedShopifyStoreDomain {
    return shopifyStoreDomain
        .replaceFirst('https://', '')
        .replaceFirst('http://', '')
        .replaceAll('/', '')
        .trim();
  }

  static bool get hasValidShopifyStoreDomain {
    return normalizedShopifyStoreDomain.isNotEmpty &&
        normalizedShopifyStoreDomain.contains('.') &&
        !normalizedShopifyStoreDomain.contains(' ');
  }

  static String get shopifyGraphqlEndpoint {
    if (normalizedShopifyStoreDomain.isEmpty) {
      return '';
    }

    return 'https://$normalizedShopifyStoreDomain/api/2026-01/graphql.json';
  }
}
