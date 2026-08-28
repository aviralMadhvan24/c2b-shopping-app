# Implementation Plan: App Completion

## Overview

This plan transforms the Niyati Mart Flutter fashion store from its current demo state (product grid, login screen, product detail with local cart/wishlist using setState) into a production-ready shopping application. The implementation proceeds in layers: dependencies and models first, then state management with Riverpod, followed by Shopify API integration, checkout/order/address features, push notifications, pagination, error handling, analytics, and testing.

## Tasks

- [x] 1. Add dependencies and set up project structure
  - [x] 1.1 Update pubspec.yaml with new dependencies
    - Add `flutter_riverpod`, `http`, `url_launcher`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics` to dependencies
    - Add `glados`, `mocktail`, `integration_test` to dev_dependencies
    - Run `flutter pub get` to resolve
    - _Requirements: 1.1, 6.1, 10.2, 13.6_

  - [x] 1.2 Create directory structure and base files
    - Create `lib/providers/`, `lib/services/`, and update `lib/repositories/` structure
    - Create `lib/models/cart_item_model.dart` with `CartItem` class including `toMap()`/`fromMap()`, `itemKey` getter, and `lineTotal` getter
    - Create `lib/models/cart_state.dart` with `CartState` class including `subtotal` and `distinctItemCount` getters
    - Create `lib/models/wishlist_state.dart` with `WishlistState` class
    - Create `lib/models/order_model.dart` with `Order`, `OrderDetail`, and `OrderLineItem` classes
    - Create `lib/models/paginated_result.dart` with `PaginatedResult<T>` class
    - Create `lib/models/pagination_state.dart` with `PaginationState<T>` class
    - Create `lib/models/app_error.dart` with `AppError` class and `AppErrorType` enum
    - Update existing models (`address_model.dart`, `product_model.dart`, `user_profile_model.dart`, `wishlist_item_model.dart`, `app_settings_model.dart`) to ensure they have complete `toMap()`/`fromMap()` serialization
    - _Requirements: 3.1, 3.10, 4.1, 8.2, 11.1, 12.1, 14.1, 14.7, 14.8_

  - [x] 1.3 Write property tests for model serialization round-trip
    - **Property 1: Model Serialization Round-Trip**
    - **Validates: Requirements 14.1, 14.7, 14.8**
    - Create `test/properties/model_serialization_test.dart`
    - Use `glados` to generate random instances of Product, Address, UserProfile, WishlistItem, AppSettings, and CartItem
    - Assert `Model.fromMap(model.toMap())` produces identical field values for each model

- [x] 2. Implement state management foundation with Riverpod
  - [x] 2.1 Set up Riverpod and AuthProvider
    - Wrap the app root with `ProviderScope` in `main.dart`
    - Create `lib/providers/auth_providers.dart` with `authServiceProvider` and `authStateProvider` (StreamProvider<User?>)
    - Refactor `AuthRepository` to expose `authStateChanges` stream
    - Ensure auth state initializes before first screen render (within 10s timeout)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 2.2 Implement AuthGate widget
    - Create `lib/widgets/auth_gate.dart` that listens to `authStateProvider`
    - Show loading indicator during `AsyncLoading` state with 10s timeout
    - Route to `LoginScreen` when unauthenticated, `HomeScreen` when authenticated
    - Handle timeout by treating user as unauthenticated
    - Allow guest access to product browsing, product detail, and cart
    - Wire into the app's root navigation replacing current routing logic
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [x] 2.3 Write widget test for AuthGate
    - Test loading state shows indicator, unauthenticated shows LoginScreen, authenticated shows HomeScreen, timeout handling
    - _Requirements: 2.1, 2.2, 2.3, 2.7_

- [x] 3. Implement Cart with quantities and Firestore sync
  - [x] 3.1 Implement CartNotifier and CartProvider
    - Create `lib/providers/cart_provider.dart` with `CartNotifier extends StateNotifier<CartState>`
    - Implement `addItem(productId, variantId, price)` — stores with quantity 1 or increments existing
    - Implement `incrementQuantity(itemKey)` — max 99
    - Implement `decrementQuantity(itemKey)` — removes at 0
    - Implement `removeItem(itemKey)`
    - Implement `subtotal` and `distinctItemCount` getters
    - Implement Firestore sync: write-through to `users/{uid}/cart/{itemKey}` within 3s for authenticated users
    - Implement `loadFromFirestore()` and `mergeLocalWithRemote()` (keep higher quantity)
    - Guest users: in-memory only
    - On sync failure: retain local state, show non-blocking error, retry on next mutation
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

  - [x] 3.2 Write property tests for Cart mutations
    - **Property 2: Cart Mutation Invariants**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
    - Create `test/properties/cart_mutations_test.dart`
    - Test add to empty cart → quantity 1, add duplicate → increment, max 99 cap, decrement to 0 removes

  - [x] 3.3 Write property test for Cart subtotal
    - **Property 3: Cart Subtotal Calculation**
    - **Validates: Requirements 3.10**
    - Create `test/properties/cart_subtotal_test.dart`
    - Test subtotal = Σ(price_i × quantity_i) for random cart contents

  - [x] 3.4 Write property test for Cart merge
    - **Property 4: Cart Merge Keeps Higher Quantity**
    - **Validates: Requirements 3.7**
    - Create `test/properties/cart_merge_test.dart`
    - Test merge of two carts keeps all items and max quantity for overlaps

  - [x] 3.5 Write unit tests for CartNotifier
    - Create `test/unit/cart_notifier_test.dart`
    - Test: add stores product ID, variant ID, quantity 1; increment by 1; decrement to 0 removes; subtotal calculation
    - _Requirements: 14.2_

- [x] 4. Implement Wishlist with Firestore sync
  - [x] 4.1 Implement WishlistNotifier and WishlistProvider
    - Create `lib/providers/wishlist_provider.dart` with `WishlistNotifier extends StateNotifier<WishlistState>`
    - Implement `addItem(productId)` — writes to `users/{uid}/wishlist/{productId}` with timestamp for authenticated users
    - Implement `removeItem(productId)` — deletes Firestore document
    - Implement `loadFromFirestore()` — loads within 10s, displays cached state until load completes
    - Implement `mergeLocalItems()` — merge local into Firestore without duplicating by product ID
    - Guest users: in-memory only
    - On failure: retain previous state, display sync error message
    - Update bottom navigation badge to show item count (hide when 0)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

  - [x] 4.2 Write property test for Wishlist merge
    - **Property 5: Wishlist Merge is Set Union Without Duplicates**
    - **Validates: Requirements 4.6**
    - Create `test/properties/wishlist_merge_test.dart`
    - Test merge produces union of product IDs with no duplicates

  - [x] 4.3 Write unit tests for WishlistNotifier
    - Create `test/unit/wishlist_notifier_test.dart`
    - Test: add stores product ID and timestamp; remove deletes entry; merge adds only non-duplicate product IDs
    - _Requirements: 14.3_

- [x] 5. Checkpoint - Core state management verified
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement Shopify Storefront API integration
  - [x] 6.1 Create ShopifyClient
    - Create `lib/services/shopify_client.dart`
    - Authenticate using Storefront Access Token from `--dart-define=SHOPIFY_TOKEN`
    - Communicate with Shopify Storefront GraphQL endpoint at configured store domain
    - Include API version `2026-01` in URL
    - Fail build if token env var is not set (compile-time assertion)
    - _Requirements: 6.1, 6.2, 6.7, 6.10_

  - [x] 6.2 Implement ShopifyProductRepository
    - Create `lib/repositories/shopify_product_repository.dart` implementing `ProductRepository`
    - Implement `fetchProducts({cursor, first: 20})` — returns `PaginatedResult<Product>` with cursor-based pagination
    - Implement `fetchProductsByCategory(category)` — queries Shopify collections, returns empty list if no match
    - Implement `fetchProductById(id)` — returns full product details with all variants
    - On error: return error with failure reason (network timeout, server error, invalid response)
    - On not found: return not-found error
    - _Requirements: 6.3, 6.4, 6.5, 6.6, 6.8, 6.9_

- [x] 7. Implement Variant Selection UI
  - [x] 7.1 Create VariantSelector widget
    - Create `lib/widgets/variant_selector.dart` as a `ConsumerWidget`
    - Display variant options grouped by option name (Size, Color)
    - Pre-select first available-for-sale variant (or first variant if none available)
    - Update displayed price and availability on option selection
    - Resolve variant from full combination of selected options across all groups
    - Disable Add to Cart and show "Sold Out" when variant is unavailable
    - Pass selected variant ID to CartProvider on Add to Cart
    - Update product image when selected variant has an associated image
    - Hide widget entirely when product has no variants
    - Integrate into `ProductDetailScreen`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

  - [x] 7.2 Write property test for Variant Resolution
    - **Property 8: Variant Resolution From Selected Options**
    - **Validates: Requirements 5.3, 5.4**
    - Create `test/properties/variant_resolution_test.dart`
    - Test resolved variant matches selected options combination; null if no match

  - [x] 7.3 Write property test for Pre-Select First Available Variant
    - **Property 9: Pre-Select First Available Variant**
    - **Validates: Requirements 5.2**
    - Create `test/properties/variant_preselect_test.dart`
    - Test pre-selection picks first availableForSale variant or first in list if none available

  - [x] 7.4 Write widget test for ProductDetailScreen with variants
    - Test variant option tap updates displayed price; sold-out disables Add to Cart button
    - _Requirements: 14.4_

- [x] 8. Implement Checkout and Payment Flow
  - [x] 8.1 Create CheckoutService
    - Create `lib/services/checkout_service.dart`
    - Implement `createShopifyCart(items)` — creates Shopify cart with variant IDs and quantities
    - Implement `openCheckoutUrl(url)` — opens checkout in in-app/external browser
    - Implement `handleCheckoutResult(redirectUri)` — detects completion/cancellation
    - Empty cart check: show message, do not initiate checkout
    - Loading indicator + disable button during cart creation (prevent duplicates)
    - On success: clear local cart, show order confirmation, log "purchase_completed" event
    - On failure/cancel: return to cart with contents preserved
    - Allow guest checkout without authentication
    - On cart creation failure: display error message with failure reason
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9_

  - [x] 8.2 Write unit tests for CheckoutService
    - Create `test/unit/checkout_service_test.dart`
    - Test: cart creation, empty cart rejection, error propagation
    - _Requirements: 7.1, 7.2, 7.9_

- [x] 9. Implement Order History
  - [x] 9.1 Create OrderRepository and OrderHistoryScreen
    - Create `lib/repositories/order_repository.dart` with `fetchOrders({cursor, first: 20})` and `fetchOrderDetail(orderId)`
    - Create `lib/screens/order_history_screen.dart` displaying orders as list items (order number, date, total, fulfillment status)
    - Create order detail view with line items, quantities, prices, shipping status
    - Guest users: show prompt to sign in instead of order history
    - Error state: full-screen error with retry button
    - Empty state: message indicating no past orders
    - Pagination: fetch next 20 orders on scroll near bottom using cursor-based pagination
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [x] 10. Implement Address Management
  - [x] 10.1 Create AddressRepository and AddressScreen
    - Create `lib/repositories/address_repository.dart`
    - Implement `fetchAddresses(userId)`, `saveAddress(userId, address)`, `deleteAddress(userId, addressId)`, `setDefaultAddress(userId, addressId)`
    - Implement `validateAddress(address)` — validate required fields non-empty after trim, enforce max lengths (name: 100, phone: 20, line1: 200, city: 100, state: 100, postalCode: 20, country: 100)
    - Enforce max 10 addresses per user
    - Setting default: update `defaultAddressId` on user profile, set `isDefault=false` on all others
    - Delete default address: remove doc + clear `defaultAddressId`
    - Create `lib/screens/address_screen.dart` showing saved addresses with "Default" label
    - Guest users: hide address management
    - Show error when validation fails or max limit reached
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8, 9.9_

  - [x] 10.2 Write property test for Address Validation
    - **Property 6: Address Validation**
    - **Validates: Requirements 9.2, 9.3**
    - Create `test/properties/address_validation_test.dart`
    - Test: empty/whitespace fields rejected, over-length fields rejected, valid fields accepted

  - [x] 10.3 Write property test for Default Address Uniqueness
    - **Property 7: Default Address Uniqueness**
    - **Validates: Requirements 9.4**
    - Create `test/properties/address_default_test.dart`
    - Test: after setting default, exactly one address has isDefault=true matching selected ID

  - [x] 10.4 Write unit tests for AddressRepository
    - Create `test/unit/address_repository_test.dart`
    - Test: save, delete, max 10 limit, default management
    - _Requirements: 9.1, 9.4, 9.5, 9.9_

- [x] 11. Checkpoint - Features verified
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Implement Push Notifications
  - [x] 12.1 Create NotificationService
    - Create `lib/services/notification_service.dart`
    - Implement `requestPermission()` — request on first launch
    - Implement `registerToken()` — register FCM token within 10s of permission grant
    - Implement `subscribeToTopics(['order_updates', 'promotions'])` for authenticated users
    - Store FCM token in user profile document in Firestore
    - Handle foreground messages: show in-app banner (title + body, 5s auto-dismiss, swipe to dismiss)
    - Handle background messages: system notification with title and body
    - Handle notification tap: navigate to associated screen from payload data
    - Permission denied: allow normal app usage, provide settings link in app settings
    - Token registration failure: retry up to 3 times with exponential backoff (2s, 4s, 8s)
    - On logout: remove FCM token from profile, unsubscribe from user-specific topics
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9_

  - [x] 12.2 Write unit tests for NotificationService
    - Create `test/unit/notification_service_test.dart`
    - Test: permission handling, retry logic, logout cleanup
    - _Requirements: 10.1, 10.7, 10.8, 10.9_

- [x] 13. Implement Pagination
  - [x] 13.1 Create PaginationNotifier and integrate with product grid
    - Create `lib/providers/pagination_provider.dart` with `PaginationNotifier extends StateNotifier<PaginationState<Product>>`
    - Implement `loadNextPage()` — fetch 20 items using cursor from previous response
    - Trigger next fetch when user scrolls within 3 items of bottom
    - Show loading indicator at bottom while loading
    - Prevent duplicate fetch requests while one is in progress
    - Stop fetching when `hasNextPage` is false
    - On failure: show error message with retry button at list bottom
    - Retain loaded products and scroll position across navigation (no re-fetch of loaded pages)
    - Integrate into `HomeScreen` product grid
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

- [x] 14. Implement Error Handling
  - [x] 14.1 Create ErrorHandler service
    - Create `lib/services/error_handler.dart`
    - Implement `classify(error)` — map errors to `AppErrorType` (noConnection, timeout, apiValidation, notFound, unknown)
    - Implement `userMessage(error)` — return user-friendly message without stack traces or internal codes
    - Network timeout threshold: 15 seconds
    - API validation errors: truncate message to 200 chars max
    - Implement `report(error, stackTrace)` — log unknown errors to Crashlytics
    - Create reusable error display widgets: inline snackbar, full-screen error state (icon + message + retry)
    - Retry button shows loading indicator while operation re-executes
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 12.7_

  - [x] 14.2 Write property test for Error Classification
    - **Property 10: Error Classification and User Message Safety**
    - **Validates: Requirements 12.1, 12.2, 12.3, 12.5**
    - Create `test/properties/error_classification_test.dart`
    - Test: all errors classified into defined types; user messages contain no stack traces, class names, or internal codes; API messages truncated to 200 chars

  - [x] 14.3 Write unit tests for ErrorHandler
    - Create `test/unit/error_handler_test.dart`
    - Test: each error type maps to correct message
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [x] 15. Implement Analytics and Crashlytics
  - [x] 15.1 Create AnalyticsService
    - Create `lib/services/analytics_service.dart`
    - Implement `logProductViewed(productId, category)` — log "product_viewed" event
    - Implement `logAddToCart(productId, variantId, price)` — log "add_to_cart" event
    - Implement `logCheckoutStarted(total, itemCount)` — log "checkout_started" event
    - Implement `logPurchaseCompleted(total, itemCount)` — log "purchase_completed" event
    - Implement `logSearch(query)` — log "search_performed" event with query truncated to 256 chars
    - Implement `setUserId(uid)` — set Firebase Analytics user ID for authenticated users
    - Implement `reportCrash(error, stackTrace)` — report to Crashlytics with anonymous user ID and auth state
    - Never log PII (email, phone, full name) in events or crash reports
    - Silent failure: discard on send failure without interrupting user
    - Wire analytics calls into existing screens and providers (product detail, cart, checkout, search)
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7, 13.8, 13.9_

  - [x] 15.2 Write property test for Search Query Truncation
    - **Property 11: Analytics Search Query Truncation**
    - **Validates: Requirements 13.5**
    - Create `test/properties/search_truncation_test.dart`
    - Test: logged query is always ≤256 chars, preserving first 256 chars verbatim

  - [x] 15.3 Write unit tests for AnalyticsService
    - Create `test/unit/analytics_service_test.dart`
    - Test: event logging, PII exclusion, silent failure
    - _Requirements: 13.1, 13.7, 13.8_

- [x] 16. Implement Cart and Wishlist UI updates
  - [x] 16.1 Refactor CartScreen and WishlistScreen to use Riverpod providers
    - Update `CartScreen` to consume `cartProvider` — show items with quantity +/- buttons, remove button, subtotal display
    - Update bottom navigation cart icon badge from `cartProvider.distinctItemCount` (hide when 0)
    - Create or update `WishlistScreen` to consume `wishlistProvider`
    - Update bottom navigation wishlist icon badge from `wishlistProvider.itemCount` (hide when 0)
    - Wire Add to Cart button on ProductDetailScreen through VariantSelector to CartProvider
    - _Requirements: 3.9, 3.10, 4.5, 5.5_

  - [x] 16.2 Write widget tests for CartScreen
    - Create `test/widget/cart_screen_test.dart`
    - Test: increase button increments quantity by 1, decrease button decrements by 1, remove eliminates item from list
    - _Requirements: 14.5_

- [x] 17. Checkpoint - Full feature integration verified
  - Ensure all tests pass, ask the user if questions arise.

- [x] 18. Integration tests
  - [x] 18.1 Write integration test for authentication flow
    - Create `test/integration/auth_flow_test.dart`
    - Verify: successful Google Sign-In navigates to HomeScreen, signing out navigates to LoginScreen
    - _Requirements: 14.6_

- [x] 19. Final checkpoint - All tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The implementation language is Dart/Flutter as specified in the design document
- Existing screens are refactored to consume Riverpod providers rather than being rewritten
- The `glados` package is used for property-based testing in Dart

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2"] },
    { "id": 2, "tasks": ["1.3", "2.1"] },
    { "id": 3, "tasks": ["2.2", "3.1", "4.1", "6.1"] },
    { "id": 4, "tasks": ["2.3", "3.2", "3.3", "3.4", "3.5", "4.2", "4.3", "6.2"] },
    { "id": 5, "tasks": ["7.1", "8.1", "9.1", "10.1", "13.1"] },
    { "id": 6, "tasks": ["7.2", "7.3", "7.4", "8.2", "10.2", "10.3", "10.4", "12.1", "14.1", "15.1", "16.1"] },
    { "id": 7, "tasks": ["12.2", "14.2", "14.3", "15.2", "15.3", "16.2"] },
    { "id": 8, "tasks": ["18.1"] }
  ]
}
```
