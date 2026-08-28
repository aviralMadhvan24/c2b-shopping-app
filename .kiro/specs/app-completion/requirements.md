# Requirements Document

## Introduction

This document defines the requirements for completing the Niyati Mart Flutter fashion store app into a production-ready shopping application. The app currently has a frontend with product grid, login screen, product detail, and local cart/wishlist. This specification covers state management, authentication gating, Firestore data sync, Shopify Storefront API integration, checkout, order history, address management, push notifications, pagination, error handling, analytics, and testing.

## Glossary

- **App**: The Niyati Mart Flutter mobile application targeting Android first
- **State_Manager**: The application-wide state management layer using a reactive provider pattern (e.g., Riverpod or Provider)
- **Auth_Gate**: The widget that routes users to LoginScreen or HomeScreen based on Firebase Auth state
- **Auth_Service**: The authentication service wrapping Firebase Auth and Google Sign-In
- **Cart_Provider**: The state provider that manages cart items, quantities, and Firestore synchronization
- **Wishlist_Provider**: The state provider that manages wishlist items and Firestore synchronization
- **Shopify_Client**: The HTTP client that communicates with the Shopify Storefront GraphQL API
- **Product_Repository**: The repository that fetches product data from the Shopify Storefront API
- **Checkout_Service**: The service that creates Shopify checkouts and handles payment flow handoff
- **Order_Repository**: The repository that retrieves order history for logged-in users
- **Address_Repository**: The repository that manages saved addresses in Cloud Firestore
- **Notification_Service**: The service that handles Firebase Cloud Messaging registration and token management
- **Analytics_Service**: The service that logs events to Firebase Analytics and reports crashes to Crashlytics
- **Pagination_Controller**: The controller that manages paginated product fetching with cursor-based loading
- **Error_Handler**: The centralized error handling and reporting mechanism
- **Variant_Selector**: The UI component that allows users to choose product variants (size, color) on the product detail screen
- **Logged_In_User**: A user who has authenticated via Google Sign-In
- **Guest_User**: A user who has not authenticated and is browsing without login

## Requirements

### Requirement 1: State Management Foundation

**User Story:** As a developer, I want a reactive state management layer, so that UI components rebuild efficiently when data changes and business logic is decoupled from widgets.

#### Acceptance Criteria

1. THE State_Manager SHALL provide application-wide state accessible to all widgets without prop drilling through the widget tree
2. WHEN a state value changes, THE State_Manager SHALL notify only the widgets that depend on that specific state value, without triggering rebuilds of unrelated widgets
3. THE State_Manager SHALL separate business logic from UI code by encapsulating state mutations in dedicated provider or notifier classes that do not import Flutter widget classes
4. WHEN the App starts, THE State_Manager SHALL initialize authentication state, cart state, and wishlist state before rendering the first screen, completing initialization within 10 seconds
5. IF the State_Manager fails to initialize within 10 seconds, THEN THE App SHALL display an error screen with a retry option

### Requirement 2: Authentication Gate

**User Story:** As a user, I want the app to show me the login screen when I am not authenticated and the home screen when I am, so that my session is respected across app restarts.

#### Acceptance Criteria

1. WHEN the App launches, THE Auth_Gate SHALL check the current Firebase Auth session state and display a loading indicator until the auth state is determined, for a maximum of 10 seconds
2. WHILE no user is authenticated, THE Auth_Gate SHALL display the LoginScreen
3. WHILE a Logged_In_User session exists, THE Auth_Gate SHALL display the HomeScreen
4. WHEN a Logged_In_User signs out, THE Auth_Gate SHALL navigate to the LoginScreen within 1 second
5. WHEN the Auth_Service emits an authentication state change from unauthenticated to authenticated, THE Auth_Gate SHALL replace the LoginScreen with the HomeScreen, and when the state changes from authenticated to unauthenticated, THE Auth_Gate SHALL replace the HomeScreen with the LoginScreen
6. THE Auth_Gate SHALL allow Guest_User access to product browsing, product detail, and cart without requiring login
7. IF the Auth_Gate does not receive an authentication state within 10 seconds of App launch, THEN THE Auth_Gate SHALL treat the user as unauthenticated and display the LoginScreen

### Requirement 3: Cart with Quantities and Firestore Sync

**User Story:** As a shopper, I want to add products to my cart with specific quantities and have my cart persist across sessions, so that I do not lose my selections.

#### Acceptance Criteria

1. WHEN a user adds a product to the cart, THE Cart_Provider SHALL store the product ID, selected variant ID, and an initial quantity of 1
2. WHEN a user adds a product that already exists in the cart with the same variant ID, THE Cart_Provider SHALL increment the existing item quantity by 1 instead of creating a duplicate entry
3. WHEN a user increases or decreases the quantity of a cart item, THE Cart_Provider SHALL update the quantity to the new value, with a maximum quantity of 99 per item
4. IF a user decreases the quantity to 0, THEN THE Cart_Provider SHALL remove the item from the cart
5. WHILE a Logged_In_User is authenticated, THE Cart_Provider SHALL persist cart changes to the Firestore subcollection users/{uid}/cart/{itemId} within 3 seconds of each change
6. IF a Firestore cart sync operation fails, THEN THE Cart_Provider SHALL retain the local cart state and display a non-blocking error indicator, retrying the sync on the next state change
7. WHEN a Logged_In_User opens the App, THE Cart_Provider SHALL load the cart from Firestore and merge it with any locally cached items, keeping the higher quantity for items that exist in both
8. WHILE a Guest_User is browsing, THE Cart_Provider SHALL store cart data in local memory only
9. THE Cart_Provider SHALL display the total number of distinct items on the bottom navigation cart icon badge, and SHALL hide the badge when the count is 0
10. THE Cart_Provider SHALL calculate and display the cart subtotal by summing each item price multiplied by its quantity

### Requirement 4: Wishlist Firestore Sync

**User Story:** As a shopper, I want my wishlist to persist across devices and sessions, so that I can find saved products later.

#### Acceptance Criteria

1. WHEN a Logged_In_User adds a product to the wishlist, THE Wishlist_Provider SHALL write the product ID and timestamp to the Firestore subcollection users/{uid}/wishlist/{productId}
2. WHEN a Logged_In_User removes a product from the wishlist, THE Wishlist_Provider SHALL delete the corresponding Firestore document
3. WHEN a Logged_In_User opens the App, THE Wishlist_Provider SHALL load the wishlist from Firestore within 10 seconds of app launch and display the cached local wishlist state until the Firestore load completes
4. WHILE a Guest_User is browsing, THE Wishlist_Provider SHALL store wishlist data in local memory only
5. WHEN the wishlist item count changes, THE Wishlist_Provider SHALL update the bottom navigation wishlist icon badge to show the current item count, and SHALL hide the badge when the count is 0
6. WHEN a Logged_In_User logs in for the first time with items in the local wishlist, THE Wishlist_Provider SHALL merge local items into the Firestore wishlist without duplicating existing entries, using the product ID to determine duplicates
7. IF a Firestore write or delete operation for a wishlist item fails, THEN THE Wishlist_Provider SHALL retain the item's previous state in the local wishlist and display an error message indicating the sync failure

### Requirement 5: Variant Selection UI

**User Story:** As a shopper, I want to select product variants such as size and color on the product detail screen, so that I add the correct item to my cart.

#### Acceptance Criteria

1. WHEN a product has variants, THE Variant_Selector SHALL display all available variant options grouped by option name (e.g., Size, Color), with the currently selected option for each group visually distinguished from unselected options
2. WHEN the product detail screen loads for a product with variants, THE Variant_Selector SHALL pre-select the first variant returned by the Product_Repository that is available for sale
3. WHEN a user selects a variant option in one option group, THE Variant_Selector SHALL update the displayed price and availability to reflect the variant matching the full combination of all currently selected options across all groups
4. WHEN a user selects a variant combination that is not available for sale, THE Variant_Selector SHALL disable the Add to Cart button and display a "Sold Out" label
5. WHEN a user taps Add to Cart, THE Variant_Selector SHALL pass the selected variant ID to the Cart_Provider along with the product ID
6. IF a product has no variants, THEN THE Variant_Selector SHALL not be displayed and the Add to Cart button SHALL use the product base price
7. WHEN a user selects a variant that has an associated image, THE Variant_Selector SHALL update the product detail screen to display the variant image

### Requirement 6: Shopify Storefront API Integration

**User Story:** As a business owner, I want the app to fetch live product data from my Shopify store, so that product information, prices, and inventory are always current.

#### Acceptance Criteria

1. THE Shopify_Client SHALL authenticate requests using the Storefront Access Token provided via compile-time environment variable
2. THE Shopify_Client SHALL communicate with the Shopify Storefront GraphQL API endpoint at the configured store domain
3. WHEN the App requests products, THE Product_Repository SHALL fetch product data including title, description, images, price, variants, and availability from the Shopify Storefront API
4. WHEN the App requests products by category, THE Product_Repository SHALL query Shopify collections matching the category name and return an empty product list if no matching collection is found
5. WHEN the App requests a single product by ID, THE Product_Repository SHALL fetch full product details including all variants with their selected options
6. IF the Shopify API returns an error or is unreachable, THEN THE Product_Repository SHALL return an error containing the failure reason (e.g., network timeout, server error, invalid response) that the UI can display to the user
7. THE Shopify_Client SHALL include the API version 2026-01 in the GraphQL endpoint URL
8. WHEN the Shopify API returns paginated results, THE Product_Repository SHALL support cursor-based pagination using pageInfo and cursor fields from the response
9. IF the App requests a single product by ID and the Shopify API returns no matching product, THEN THE Product_Repository SHALL return a not-found error that the UI can use to display a "product not available" state
10. IF the Storefront Access Token environment variable is not set at compile time, THEN THE Shopify_Client SHALL fail the build with an error indicating the missing configuration

### Requirement 7: Checkout and Payment Flow

**User Story:** As a shopper, I want to proceed to checkout and pay for my items securely, so that I can complete my purchase.

#### Acceptance Criteria

1. WHEN a user taps the checkout button and the cart contains at least one item, THE Checkout_Service SHALL create a Shopify cart with all items from the Cart_Provider including variant IDs and quantities
2. IF the user taps the checkout button and the cart is empty, THEN THE App SHALL display a message indicating the cart is empty and SHALL NOT initiate the checkout process
3. WHILE the Shopify cart is being created, THE App SHALL display a loading indicator and disable the checkout button to prevent duplicate submissions
4. WHEN the Shopify cart is created successfully, THE Checkout_Service SHALL retrieve the checkout URL from the Shopify API response
5. THE Checkout_Service SHALL open the Shopify-hosted checkout URL in an in-app browser or external browser
6. THE App SHALL allow Guest_User checkout without requiring authentication
7. WHEN the checkout completes successfully (detected via redirect URL or callback), THE App SHALL clear the local cart, display an order confirmation screen with the order reference, and log a "purchase_completed" analytics event
8. WHEN the checkout fails or is cancelled by the user closing the browser, THE App SHALL return the user to the cart screen with cart contents preserved
9. IF the Shopify cart creation fails, THEN THE Checkout_Service SHALL display an error message describing the failure reason to the user

### Requirement 8: Order History

**User Story:** As a logged-in user, I want to view my past orders, so that I can track deliveries and reference previous purchases.

#### Acceptance Criteria

1. WHEN a Logged_In_User navigates to the order history screen, THE Order_Repository SHALL fetch the most recent 20 orders sorted by date descending from the Shopify Customer API or stored order references
2. WHEN the order history is loaded, THE App SHALL display each order as a list item showing order number, date, total amount, and fulfillment status
3. WHEN a user taps an order, THE App SHALL display order details including line items, quantities, prices, and shipping status
4. WHILE a Guest_User is browsing, THE App SHALL not display order history and SHALL show a prompt to sign in
5. IF the Order_Repository fails to fetch orders, THEN THE App SHALL display an error state with a retry button that re-triggers the order fetch
6. IF the Order_Repository returns zero orders for the Logged_In_User, THEN THE App SHALL display an empty state indicating the user has no past orders
7. WHEN the user scrolls near the bottom of the order history list and more orders are available, THE Order_Repository SHALL fetch the next page of 20 orders using cursor-based pagination

### Requirement 9: Address Management

**User Story:** As a logged-in user, I want to save and manage delivery addresses, so that I can select a saved address during checkout.

#### Acceptance Criteria

1. WHILE a Logged_In_User is authenticated, THE Address_Repository SHALL store addresses in the Firestore subcollection users/{uid}/addresses/{addressId} up to a maximum of 10 addresses per user
2. WHEN a user adds a new address, THE Address_Repository SHALL validate that name (maximum 100 characters), phone (maximum 20 characters), line1 (maximum 200 characters), city (maximum 100 characters), state (maximum 100 characters), postal code (maximum 20 characters), and country (maximum 100 characters) are provided and non-empty after trimming whitespace
3. IF address validation fails due to missing or empty required fields, THEN THE Address_Repository SHALL reject the save operation and THE App SHALL display an error message indicating which fields are missing or invalid
4. WHEN a user sets an address as default, THE Address_Repository SHALL update the defaultAddressId field on the user profile document and set isDefault to false on all other addresses
5. WHEN a user deletes an address that is not the default, THE Address_Repository SHALL remove the address document from Firestore
6. WHEN a user deletes the default address, THE Address_Repository SHALL remove the address document from Firestore and clear the defaultAddressId field on the user profile document
7. THE App SHALL display a list of saved addresses on the profile screen with the default address visually distinguished by a "Default" label
8. WHILE a Guest_User is browsing, THE App SHALL not display address management options
9. IF a user attempts to add an address when 10 addresses are already stored, THEN THE App SHALL display an error message indicating the maximum address limit has been reached

### Requirement 10: Push Notifications

**User Story:** As a user, I want to receive push notifications about order updates and promotions, so that I stay informed about my purchases and deals.

#### Acceptance Criteria

1. WHEN the App launches for the first time after installation, THE Notification_Service SHALL request notification permission from the user before any other notification-related operations are performed
2. WHEN notification permission is granted, THE Notification_Service SHALL register the device token with Firebase Cloud Messaging within 10 seconds of permission being granted
3. WHEN a Logged_In_User is authenticated, THE Notification_Service SHALL store the FCM token in the user profile document in Firestore and subscribe the device to the "order_updates" and "promotions" notification topics
4. WHEN a push notification is received while the App is in the foreground, THE Notification_Service SHALL display an in-app notification banner showing the notification title and body for 5 seconds before automatically dismissing, and the banner SHALL be manually dismissible by the user via swipe
5. WHEN a push notification is received while the App is in the background, THE Notification_Service SHALL display a system notification showing the notification title and body
6. WHEN a user taps a received push notification, THE Notification_Service SHALL navigate the user to the screen associated with the notification payload data (e.g., order detail screen for order updates, promotion screen for promotions)
7. IF notification permission is denied, THEN THE Notification_Service SHALL not attempt to register a token, SHALL allow the user to use the App without notifications, and SHALL provide an option in the App settings to direct the user to the device notification settings
8. IF FCM token registration fails, THEN THE Notification_Service SHALL retry registration up to 3 times with exponential backoff and SHALL allow the user to continue using the App without notifications if all retries fail
9. WHEN a Logged_In_User logs out, THE Notification_Service SHALL remove the FCM token from the user profile document in Firestore and unsubscribe the device from user-specific notification topics

### Requirement 11: Pagination

**User Story:** As a user browsing products, I want the product list to load progressively, so that the app remains fast and does not load all products at once.

#### Acceptance Criteria

1. WHEN the App loads the product grid, THE Pagination_Controller SHALL fetch the first page of products with a maximum of 20 items per page
2. WHEN the user scrolls within 3 items of the bottom of the product grid, THE Pagination_Controller SHALL fetch the next page of products using the cursor from the previous response
3. WHILE additional pages are loading, THE Pagination_Controller SHALL display a loading indicator at the bottom of the list
4. WHILE a page fetch is in progress, THE Pagination_Controller SHALL not initiate another fetch request until the current one completes or fails
5. WHEN no more pages are available (the API response indicates hasNextPage is false), THE Pagination_Controller SHALL stop fetching and not display a loading indicator
6. IF a page fetch fails, THEN THE Pagination_Controller SHALL display an error message with a retry button at the bottom of the list, and tapping the retry button SHALL re-fetch the same page that failed
7. WHEN the user navigates away from the product grid and returns, THE Pagination_Controller SHALL retain the previously loaded products and scroll position without re-fetching already loaded pages

### Requirement 12: Error Handling

**User Story:** As a user, I want to see clear error messages when something goes wrong, so that I understand what happened and can take action.

#### Acceptance Criteria

1. WHEN a network request fails due to no internet connection, THE Error_Handler SHALL display a "No internet connection" message with a retry button
2. WHEN a network request times out after 15 seconds, THE Error_Handler SHALL display a "Request timed out" message with a retry button
3. WHEN the Shopify API returns a validation error, THE Error_Handler SHALL display the error message from the API response truncated to a maximum of 200 characters
4. IF an unexpected error occurs, THEN THE Error_Handler SHALL log the error to Crashlytics and display a generic "Something went wrong. Please try again." message to the user with a retry button
5. THE Error_Handler SHALL not expose stack traces, internal error codes, or technical details to the user
6. WHEN a screen fails to load data, THE Error_Handler SHALL display a full-screen error state with an icon, descriptive message, and retry button replacing the screen content
7. WHEN the user taps a retry button after an error, THE Error_Handler SHALL re-execute the failed operation and display a loading indicator while the operation is in progress

### Requirement 13: Analytics and Crashlytics

**User Story:** As a business owner, I want to track user behavior and app crashes, so that I can make data-driven decisions and fix issues quickly.

#### Acceptance Criteria

1. WHEN a user views a product detail screen, THE Analytics_Service SHALL log a "product_viewed" event with the product ID and category
2. WHEN a user adds an item to cart, THE Analytics_Service SHALL log an "add_to_cart" event with the product ID, variant ID, and price
3. WHEN a user begins checkout, THE Analytics_Service SHALL log a "checkout_started" event with the cart total and item count
4. WHEN a user completes a purchase, THE Analytics_Service SHALL log a "purchase_completed" event with the order total and item count
5. WHEN a user performs a search, THE Analytics_Service SHALL log a "search_performed" event with the search query truncated to a maximum of 256 characters
6. WHEN an unhandled exception occurs, THE Analytics_Service SHALL report the exception to Firebase Crashlytics with the stack trace, anonymous user ID, and authentication state (logged-in or guest)
7. THE Analytics_Service SHALL not log personally identifiable information such as email addresses, phone numbers, or full names in analytics events or crash reports
8. IF the Analytics_Service fails to send an event or crash report, THEN THE Analytics_Service SHALL silently discard the event without interrupting the user's current action or displaying an error
9. WHILE a Logged_In_User is authenticated, THE Analytics_Service SHALL set the Firebase Analytics user ID to the Firebase Auth UID

### Requirement 14: Testing

**User Story:** As a developer, I want comprehensive test coverage, so that I can refactor and extend the app with confidence that existing functionality remains correct.

#### Acceptance Criteria

1. THE App SHALL have unit tests for model classes Product, Address, UserProfile, WishlistItem, AppSettings, and CartItem validating that serializing an instance to a map and deserializing it back produces an object with identical field values
2. THE App SHALL have unit tests for Cart_Provider verifying: adding a product stores product ID, variant ID, and quantity of 1; increasing quantity increments the stored value by 1; decreasing quantity to 0 removes the item; and subtotal equals the sum of each item price multiplied by its quantity
3. THE App SHALL have unit tests for Wishlist_Provider verifying: adding a product stores the product ID and timestamp; removing a product deletes the entry; and merging local items into an existing Firestore wishlist adds only items whose product IDs are not already present
4. THE App SHALL have widget tests for ProductDetailScreen verifying that tapping a variant option updates the displayed price to the selected variant price within the same frame
5. THE App SHALL have widget tests for the cart screen verifying that tapping the increase button increments the displayed quantity by 1, tapping the decrease button decrements the displayed quantity by 1, and tapping remove eliminates the item from the rendered list
6. THE App SHALL have integration tests for the authentication flow verifying that a successful Google Sign-In navigates to HomeScreen and that signing out navigates to LoginScreen
7. WHEN a valid Product object is serialized to a map and then deserialized from that map, THE App test suite SHALL confirm that the resulting Product object has identical values for all fields including id, name, price, category, variants, and availability
8. WHEN a valid Address object is serialized to a map and then deserialized from that map, THE App test suite SHALL confirm that the resulting Address object has identical values for all fields including id, name, phone, line1, city, state, postalCode, country, and isDefault
9. THE App SHALL achieve a minimum of 100% pass rate on all unit and widget tests when executed via the flutter test command with no skipped tests
