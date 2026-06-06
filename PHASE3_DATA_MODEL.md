# Phase 3 Data Model

## Status

Phase 3 is implemented in code using plain Dart models.

The app still uses demo product data until Shopify and Firebase are externally configured, but the model layer now matches the production backend plan.

## Product Model

Implemented in:

- `lib/models/product_model.dart`

Production-ready fields:

- product ID
- name
- image
- price
- currency code
- category
- rating
- description
- variants

Variant fields:

- variant ID
- title
- price
- currency code
- availability
- quantity available
- selected options such as size and color

Demo products now include:

- stable demo product IDs
- stable demo variant IDs
- size/color selected options
- quantity available

## Firebase User Models

Implemented:

- `lib/models/user_profile_model.dart`
- `lib/models/address_model.dart`
- `lib/models/wishlist_item_model.dart`
- `lib/models/app_settings_model.dart`

Firestore-style structures:

```text
users/{userId}
users/{userId}/addresses/{addressId}
users/{userId}/wishlist/{productId}
appSettings/public
```

Important rule:

- Wishlist stores only product and variant references, not full product data.

## Current Boundaries

This phase does not connect to Firebase or Shopify yet.

Reason:

- Firebase requires external project setup and generated `firebase_options.dart`.
- Shopify requires a store domain and Storefront API token.

Those are tracked in `PHASE2_SETUP.md`.

## Tests

Added:

- product ID and variant checks
- user profile serialization checks
- address serialization checks
- wishlist reference-only checks
- app settings default checks

