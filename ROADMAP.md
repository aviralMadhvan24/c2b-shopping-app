# Fashion Store Production Roadmap

## Goal

Turn the current Flutter-only fashion store into a production-ready shopping app for real users, with a reliable backend, secure payments, manageable products, and safe operational workflows.

## Recommended Architecture

Use Shopify as the core commerce backend and Firebase for app-specific features.

```text
Flutter App
  -> Shopify Storefront API: products, variants, cart, checkout, orders
  -> Firebase Auth: user authentication
  -> Cloud Firestore: wishlist, saved addresses, app-specific user data
  -> Firebase Cloud Functions: secure server-side logic and webhooks
  -> Firebase Cloud Messaging: push notifications
  -> Analytics/Crashlytics: production monitoring
```

Why this setup:

- Shopify already handles the hard commerce parts: products, inventory, orders, discounts, taxes, shipping, refunds, and admin management.
- Firebase works well with Flutter and is ideal for user profiles, wishlist, notifications, analytics, and lightweight app data.
- Payments should be handled through Shopify Payments, Stripe, Razorpay, or another production payment provider, not directly inside app-only code.

## Selected Production Settings

- Checkout mode: guest checkout allowed.
- Auth methods: email/password and Google sign-in.
- Product backend: Shopify.
- Payment provider: Shopify Payments if available; otherwise Razorpay for India.
- Wishlist: required.
- Saved addresses: required for logged-in users.
- Order history inside app: required for logged-in users.
- Push notifications: required.
- Coupons/discounts: managed through Shopify.
- Returns/refunds: managed through Shopify admin.
- Target platforms: Android first.

## Phase 1: Project Audit And Cleanup

Status: completed. See `PHASE1_AUDIT.md`.

- Review current Flutter screens and flows.
- Identify all hardcoded product, cart, and category data.
- Remove unused dependencies and generated files from decision-making.
- Confirm target platforms: Android, iOS, Web, or all.
- Define production requirements:
  - guest checkout or login-required checkout
  - wishlist
  - saved addresses
  - order history
  - push notifications
  - admin product management
  - coupons and discounts
  - returns/refunds

## Phase 2: Backend Decision And Accounts

Status: coding scaffold complete. External Shopify and Firebase console setup required. See `PHASE2_SETUP.md`.

- Create or choose the Shopify store.
- Configure Shopify products, variants, sizes, colors, images, inventory, taxes, and shipping.
- Enable Storefront API access.
- Create a Firebase project.
- Add Firebase apps for Android, iOS, and Web as needed.
- Enable Firebase services:
  - Authentication
  - Cloud Firestore
  - Cloud Functions
  - Cloud Messaging
  - Analytics
  - Crashlytics
  - App Check

## Phase 3: Data Model

Status: completed in code with plain Dart models. See `PHASE3_DATA_MODEL.md`.

Shopify data:

- products
- collections/categories
- variants
- inventory
- discounts
- cart
- checkout
- orders

Firebase data:

```text
users/{userId}
  name
  email
  phone
  createdAt
  defaultAddressId

users/{userId}/wishlist/{productId}
  productId
  variantId
  addedAt

users/{userId}/addresses/{addressId}
  name
  phone
  line1
  line2
  city
  state
  postalCode
  country
  isDefault

appSettings/public
  maintenanceMode
  featuredCollectionId
  supportEmail
```

Rules:

- Do not store payment card details in Firebase.
- Do not duplicate full Shopify product data in Firebase unless there is a clear reason.
- Store only references such as Shopify product IDs, variant IDs, cart IDs, and checkout URLs.

## Phase 4: Flutter App Integration

Status: started. Repository layer added. See `PHASE4_INTEGRATION.md`.

- Add Firebase packages:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_messaging`
  - `firebase_analytics`
  - `firebase_crashlytics`
  - `firebase_app_check`
- Add API/client package for Shopify requests:
  - `graphql_flutter` or a small typed HTTP client
- Replace `lib/data/products.dart` with Shopify product fetching.
- Add loading, empty, and error states for product screens.
- Add pagination for product lists.
- Add search and category filtering through Shopify collections/search.
- Add cart creation and cart updates through Shopify Storefront API.
- Add checkout handoff through Shopify checkout/payment flow.

## Phase 5: Authentication

- Decide sign-in methods:
  - email/password
  - Google sign-in
  - phone OTP if required
- Implement Firebase Auth.
- Create user profile document after first login.
- Protect profile, wishlist, and address data with Firestore Security Rules.
- Add logout and account deletion flow.

## Phase 6: Wishlist And User Data

- Implement wishlist using Firestore.
- Save only Shopify product/variant IDs in wishlist.
- Fetch live product details from Shopify when displaying wishlist.
- Implement saved addresses if checkout flow requires them.
- Add user profile edit screen.

## Phase 7: Cart, Checkout, And Orders

- Use Shopify cart APIs for:
  - create cart
  - add item
  - update quantity
  - remove item
  - apply discount
  - get checkout URL
- Use Shopify checkout/payment flow or payment gateway integration.
- Keep payment confirmation server-side through Shopify/payment provider webhooks.
- Add order history using Shopify customer/order APIs if supported by chosen setup.
- Add post-checkout success and failure screens.

## Phase 8: Security

- Enable Firebase App Check.
- Write strict Firestore Security Rules.
- Do not expose admin API keys in Flutter.
- Store secret keys only in server-side environments.
- Use Cloud Functions for any privileged backend action.
- Validate all webhook signatures.
- Add rate limiting where needed.
- Use billing alerts in Firebase and Shopify/payment providers.

## Phase 9: Admin And Operations

- Use Shopify Admin for product, inventory, order, discount, and refund management.
- Create an operational checklist:
  - add products
  - update stock
  - process orders
  - handle refunds
  - manage discounts
  - respond to customer issues
- Add customer support contact details in app settings.
- Add maintenance mode support from Firebase.

## Phase 10: Notifications

- Configure Firebase Cloud Messaging.
- Add notification permission handling.
- Store user notification tokens securely.
- Send notifications for:
  - order updates
  - promotions
  - abandoned cart reminders if legally/commercially appropriate
  - back-in-stock alerts
- Respect opt-out preferences.

## Phase 11: Analytics And Monitoring

- Add Firebase Analytics events:
  - product_viewed
  - add_to_cart
  - remove_from_cart
  - checkout_started
  - purchase_completed
  - wishlist_added
  - search_performed
- Add Crashlytics.
- Add performance monitoring if needed.
- Track API failures and checkout drop-offs.
- Add production logging for Cloud Functions.

## Phase 12: Testing

- Add unit tests for models and API parsing.
- Add widget tests for major screens.
- Add integration tests for:
  - product browsing
  - product detail
  - cart updates
  - login/logout
  - wishlist
  - checkout handoff
- Test offline and poor-network behavior.
- Test Android and iOS release builds.

## Phase 13: Production Release

- Configure app name, icon, splash screen, and package IDs.
- Set up release signing for Android.
- Set up iOS certificates and provisioning.
- Configure privacy policy and terms pages.
- Confirm payment, refund, shipping, and return policies.
- Run final security review.
- Run final QA on real devices.
- Publish to internal testing.
- Publish to production after successful test orders.

## Phase 14: Cost Control

- Set Firebase budget alerts.
- Avoid excessive Firestore reads.
- Paginate all large lists.
- Do not keep realtime listeners open unless truly needed.
- Cache product data where appropriate.
- Monitor Cloud Functions usage.
- Review Shopify app and transaction costs.

## Step-By-Step Execution Order

1. Confirm final backend architecture.
2. Create Firebase project.
3. Add Firebase to Flutter.
4. Set up Firebase Auth.
5. Set up Firestore user profile and wishlist structure.
6. Write Firestore Security Rules.
7. Create Shopify store and configure products.
8. Enable Shopify Storefront API.
9. Build Shopify API client in Flutter.
10. Replace hardcoded product data with live Shopify data.
11. Implement product detail with variants.
12. Implement cart using Shopify cart API.
13. Implement checkout handoff.
14. Add order success/failure handling.
15. Add wishlist.
16. Add saved addresses if needed.
17. Add push notifications.
18. Add analytics and Crashlytics.
19. Add tests.
20. Prepare production release.

## Current Project State

- The app is currently frontend-only.
- Product data is hardcoded in `lib/data/products.dart`.
- There is no production backend integration yet.
- There is no authentication, real cart persistence, payment flow, order management, or admin backend yet.
