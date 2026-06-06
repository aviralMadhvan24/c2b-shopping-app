import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store/config/backend_config.dart';

void main() {
  test('backend config is empty until external accounts are connected', () {
    expect(BackendConfig.shopifyStoreDomain, isEmpty);
    expect(BackendConfig.shopifyStorefrontAccessToken, isEmpty);
    expect(BackendConfig.firebaseProjectId, isEmpty);
    expect(BackendConfig.hasShopifyConfig, isFalse);
    expect(BackendConfig.hasFirebaseProjectId, isFalse);
    expect(BackendConfig.normalizedShopifyStoreDomain, isEmpty);
    expect(BackendConfig.hasValidShopifyStoreDomain, isFalse);
    expect(BackendConfig.shopifyGraphqlEndpoint, isEmpty);
  });
}
