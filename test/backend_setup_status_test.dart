import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/backend/backend_setup_status.dart';

void main() {
  test('reports all setup steps missing when values are empty', () {
    const status = BackendSetupStatus(
      shopifyStoreDomain: '',
      shopifyStorefrontAccessToken: '',
      firebaseProjectId: '',
    );

    expect(status.isReadyForApiClient, isFalse);
    expect(status.missingSteps, [
      BackendSetupStep.shopifyStoreDomain,
      BackendSetupStep.shopifyStorefrontAccessToken,
      BackendSetupStep.firebaseProjectId,
    ]);
  });

  test('normalizes Shopify domain and reports complete config', () {
    const status = BackendSetupStatus(
      shopifyStoreDomain: 'https://demo-store.myshopify.com/',
      shopifyStorefrontAccessToken: 'storefront-token',
      firebaseProjectId: 'fashion-store',
    );

    expect(status.normalizedShopifyStoreDomain, 'demo-store.myshopify.com');
    expect(status.hasValidShopifyStoreDomain, isTrue);
    expect(status.hasShopifyStorefrontAccessToken, isTrue);
    expect(status.hasFirebaseProjectId, isTrue);
    expect(status.isReadyForApiClient, isTrue);
    expect(status.missingSteps, isEmpty);
  });
}
