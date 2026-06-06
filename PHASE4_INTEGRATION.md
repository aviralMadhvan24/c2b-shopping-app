# Phase 4 Flutter App Integration

## Status

Phase 4 has started with a repository layer.

Implemented:

- Product repository interface.
- Demo product repository.
- App repository container.
- Home screen now reads products through the repository.
- Category screen now reads category products through the repository.
- Loading and empty states for product grids.

Files:

- `lib/repositories/product_repository.dart`
- `lib/repositories/demo_product_repository.dart`
- `lib/repositories/app_repositories.dart`

## Why This Comes Before Shopify API Code

The repository layer lets the app keep working with demo products while preparing for Shopify.

Later, `DemoProductRepository` can be replaced with a Shopify-backed repository without rewriting the UI.

## Waiting On External Setup

To continue with real Shopify/Firebase integration, the app needs:

- Shopify store domain.
- Shopify Storefront API access token.
- Firebase project.
- Generated `lib/firebase_options.dart` from `flutterfire configure`.

