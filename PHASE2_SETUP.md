# Phase 2 Setup

## Status

Phase 2 is prepared in the repo, but external account setup is still required.

The app now has backend configuration placeholders in:

- `lib/config/backend_config.dart`
- `lib/backend/backend_setup_status.dart`

These values are read from `--dart-define` so real account values do not need to be hardcoded.

## Selected Backend Setup

- Commerce backend: Shopify.
- App backend: Firebase.
- First platform: Android.
- Checkout: guest checkout allowed.
- Auth: email/password and Google sign-in.
- Payments: Shopify Payments if available; otherwise Razorpay for India.

## Shopify Setup

Create or choose a Shopify store.

Configure in Shopify admin:

- Products.
- Product variants:
  - sizes
  - colors
  - SKUs
  - prices
  - stock/inventory
- Product images.
- Collections/categories.
- Taxes.
- Shipping.
- Discounts.
- Return/refund policy.

Enable Storefront API access:

- Create/configure a custom app or Storefront API access path in Shopify.
- Grant unauthenticated Storefront API scopes needed for the app:
  - read products
  - read collections
  - create/update carts
  - access checkout URL
- Copy the Storefront access token.
- Confirm the store domain, for example:

```text
your-store-name.myshopify.com
```

Run the app with Shopify config:

```powershell
flutter run --dart-define=SHOPIFY_STORE_DOMAIN=your-store-name.myshopify.com --dart-define=SHOPIFY_STOREFRONT_ACCESS_TOKEN=your_storefront_token
```

Official references:

- Shopify custom apps and Storefront API access: https://help.shopify.com/en/manual/apps
- Shopify Storefront access tokens: https://shopify.dev/docs/api/admin-rest/latest/resources/storefrontaccesstoken
- Shopify Storefront cart API: https://shopify.dev/docs/storefronts/headless/building-with-the-storefront-api/cart/manage

## Firebase Setup

Create a Firebase project.

Recommended project name:

```text
fashion-store
```

Enable Google Analytics for the Firebase project.

Add an Android app in Firebase. Use the Android package name from:

```text
android/app/build.gradle.kts
```

Current package namespace:

```text
com.example.fashion_store
```

For production, this should later be changed to a real package name, for example:

```text
com.yourbrand.fashionstore
```

Enable Firebase services:

- Authentication.
- Cloud Firestore.
- Cloud Functions.
- Cloud Messaging.
- Analytics.
- Crashlytics.
- App Check.

Authentication providers to enable:

- Email/password.
- Google.

## FlutterFire Setup

Install Firebase CLI and FlutterFire CLI if needed.

From the project root:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Select:

- the Firebase project you created
- Android as the first platform

The command should generate:

```text
lib/firebase_options.dart
```

Official Firebase Flutter setup reference:

- https://firebase.google.com/docs/flutter/setup

## Phase 2 Verification Checklist

Complete these before Phase 3:

- Shopify store exists.
- Shopify test products exist.
- Shopify Storefront API access token is copied.
- Firebase project exists.
- Firebase Android app is registered.
- `flutterfire configure` has generated `lib/firebase_options.dart`.
- Firebase Authentication is enabled for email/password and Google.
- Cloud Firestore is enabled.
- Cloud Messaging is enabled.
- Analytics is enabled.
- Crashlytics is enabled.
- App Check is enabled or scheduled before public release.

## Current Repo-Side Completion

Completed:

- Added backend config placeholders.
- Added backend readiness checks.
- Added Phase 2 setup instructions.
- Added tests for empty backend config.
- Added tests for complete backend setup status.

Still needs external setup:

- Shopify account/store/API token.
- Firebase project and Android app.
- Generated Firebase options file.
