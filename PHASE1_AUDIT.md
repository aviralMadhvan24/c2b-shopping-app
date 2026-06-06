# Phase 1 Audit

## Summary

The project is currently a Flutter frontend prototype. It has no real backend, no authentication, no persistent cart, no payment flow, no order system, and no admin/product management integration.

Current production readiness: not production-ready yet.

## Current App Structure

Main files:

- `lib/main.dart` starts the app and loads `HomeScreen`.
- `lib/screens/home_screen.dart` contains the main home, wishlist, cart, and profile tab UI.
- `lib/screens/category_screen.dart` filters hardcoded products by category.
- `lib/screens/product_detail_screen.dart` displays a product detail page.
- `lib/screens/cart_screen.dart` exists but is not currently used by the main app flow.
- `lib/data/products.dart` contains all product data.
- `lib/models/product_model.dart` defines a simple product model.
- `lib/widgets/*` contains reusable UI widgets.

## Existing User Flows

Implemented:

- Browse home screen.
- See hardcoded categories.
- See hardcoded popular products.
- Open category pages.
- Open product detail pages.
- Add a product to an in-memory cart.
- Remove a product from the in-memory cart.
- Add/remove a product from an in-memory wishlist.
- See a placeholder profile tab.

Missing:

- Real search behavior.
- Login/signup.
- Persistent user profile.
- Persistent wishlist.
- Persistent cart.
- Product variants such as size, color, SKU, and stock.
- Real checkout.
- Payment processing.
- Order creation.
- Order history.
- Address management.
- Push notifications.
- Admin/backend product management.
- Error, loading, and empty states for backend data.

## Hardcoded Data

Hardcoded product data:

- `lib/data/products.dart`
  - product names
  - image URLs
  - prices
  - categories
  - ratings
  - descriptions

Hardcoded categories:

- `Men`
- `Women`
- `Children`, displayed as `Kids`
- `Gadgets`

Hardcoded promotional content:

- `Mega Fashion Sale`
- `Up to 50% OFF`

Hardcoded app title/brand:

- `Fashion Store`
- `FashionHub`

## State Management

Current state lives inside `HomeScreen`:

- `cartProducts`
- `wishlistProducts`
- `currentIndex`

This state is lost when the app restarts. It is also not tied to a logged-in user.

Current cart limitations:

- Stores only unique products.
- No quantities.
- No variants.
- No shipping/tax/discount handling.
- No checkout URL.
- No backend cart ID.

Current wishlist limitations:

- Stores full local `Product` objects in memory.
- No user persistence.
- No backend product IDs.

## Dependencies

Current production dependencies:

- `google_fonts`
- `carousel_slider`
- `flutter_staggered_grid_view`
- `iconsax`
- `cupertino_icons`

No backend dependencies are installed yet.

Not currently present:

- Firebase packages.
- Shopify API client.
- GraphQL client.
- HTTP API layer in `lib`.
- Local database/storage package.
- Auth package.
- Payment SDK.

Note: `pubspec.lock` contains transitive packages such as `http`, but the app is not using them directly.

## Generated Files

These folders are generated or platform/tooling output and should not drive backend decisions:

- `.dart_tool`
- `build`
- platform runner folders unless configuring release/platform integration:
  - `android`
  - `ios`
  - `web`
  - `linux`
  - `macos`
  - `windows`

They should be considered only when configuring Firebase, app IDs, signing, web setup, or release builds.

## Testing Baseline

`flutter analyze` result:

- Passed.
- No analyzer issues found.

`flutter test` result:

- Failed.
- Existing `test/widget_test.dart` is still the default counter test and does not match this app.
- Network images fail in widget tests because Flutter widget tests block real HTTP requests and return status code 400.

Required test cleanup:

- Replace the default counter test with app-specific tests.
- Avoid real network image loading in widget tests.
- Add tests after product data is abstracted behind a repository/API layer.

## Target Platform Decision

Selected first production target:

- Android first.

Future platform path:

- Add iOS after the backend and Android checkout flow are stable.
- Keep Web optional unless there is a specific business need.

Reason:

- Android-first reduces release complexity.
- Firebase and Shopify setup can still support iOS/Web later.

## Selected Production Requirements

These settings are selected for the first production version:

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

Implementation notes:

- Guest checkout should stay available so users can buy without account friction.
- Login should be required for wishlist, saved addresses, profile, and order history.
- Phone OTP should be treated as a later enhancement unless it becomes a business requirement.
- Shopify should own products, inventory, coupons, checkout, payments, orders, returns, and refunds.
- Firebase should own app auth, wishlist metadata, saved-address metadata, push notifications, analytics, and crash reporting.
- Use Shopify checkout/payment flow first instead of building a custom payment flow in the app.

## Phase 1 Completion Status

Completed:

- Reviewed current Flutter screens and flows.
- Identified hardcoded product, category, promotion, and brand data.
- Checked current dependencies.
- Separated generated files from decision-making.
- Ran analyzer baseline.
- Ran test baseline and documented failures.

Unblocked:

- Final target platform is selected as Android first.
- Checkout/auth behavior is selected.
- Shopify + Firebase is selected as the production backend path.

Ready for Phase 2:

- Create/configure Shopify store.
- Create/configure Firebase project.
- Prepare Android Firebase app setup.
