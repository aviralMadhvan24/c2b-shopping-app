import '../config/backend_config.dart';

class BackendSetupStatus {
  const BackendSetupStatus({
    required this.shopifyStoreDomain,
    required this.shopifyStorefrontAccessToken,
    required this.firebaseProjectId,
  });

  factory BackendSetupStatus.fromEnvironment() {
    return const BackendSetupStatus(
      shopifyStoreDomain: BackendConfig.shopifyStoreDomain,
      shopifyStorefrontAccessToken: BackendConfig.shopifyStorefrontAccessToken,
      firebaseProjectId: BackendConfig.firebaseProjectId,
    );
  }

  final String shopifyStoreDomain;
  final String shopifyStorefrontAccessToken;
  final String firebaseProjectId;

  String get normalizedShopifyStoreDomain {
    return shopifyStoreDomain
        .replaceFirst('https://', '')
        .replaceFirst('http://', '')
        .replaceAll('/', '')
        .trim();
  }

  bool get hasValidShopifyStoreDomain {
    return normalizedShopifyStoreDomain.isNotEmpty &&
        normalizedShopifyStoreDomain.contains('.') &&
        !normalizedShopifyStoreDomain.contains(' ');
  }

  bool get hasShopifyStorefrontAccessToken {
    return shopifyStorefrontAccessToken.trim().isNotEmpty;
  }

  bool get hasFirebaseProjectId {
    return firebaseProjectId.trim().isNotEmpty;
  }

  bool get isReadyForApiClient {
    return hasValidShopifyStoreDomain &&
        hasShopifyStorefrontAccessToken &&
        hasFirebaseProjectId;
  }

  List<BackendSetupStep> get missingSteps {
    return BackendSetupStep.values.where((step) {
      return switch (step) {
        BackendSetupStep.shopifyStoreDomain => !hasValidShopifyStoreDomain,
        BackendSetupStep.shopifyStorefrontAccessToken =>
          !hasShopifyStorefrontAccessToken,
        BackendSetupStep.firebaseProjectId => !hasFirebaseProjectId,
      };
    }).toList();
  }
}

enum BackendSetupStep {
  shopifyStoreDomain,
  shopifyStorefrontAccessToken,
  firebaseProjectId,
}
