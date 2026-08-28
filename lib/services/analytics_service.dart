import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Service responsible for logging analytics events to Firebase Analytics
/// and reporting crashes to Firebase Crashlytics.
///
/// All event logging is fire-and-forget — failures are silently discarded
/// without interrupting the user's current action.
///
/// PII (email, phone, full name) is never logged in analytics events or
/// crash reports.
class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  /// Maximum length for search query parameters logged to analytics.
  static const int maxSearchQueryLength = 256;

  /// Creates an [AnalyticsService] instance.
  ///
  /// Optionally accepts [FirebaseAnalytics] and [FirebaseCrashlytics]
  /// instances for testing.
  AnalyticsService({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  })  : _analytics = analytics ?? FirebaseAnalytics.instance,
        _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  /// Logs a "product_viewed" event with the product ID and category.
  ///
  /// Requirements: 13.1
  void logProductViewed(String productId, String category) {
    _safeLog(() => _analytics.logEvent(
          name: 'product_viewed',
          parameters: {
            'product_id': productId,
            'category': category,
          },
        ));
  }

  /// Logs an "add_to_cart" event with the product ID, variant ID, and price.
  ///
  /// Requirements: 13.2
  void logAddToCart(String productId, String variantId, double price) {
    _safeLog(() => _analytics.logEvent(
          name: 'add_to_cart',
          parameters: {
            'product_id': productId,
            'variant_id': variantId,
            'price': price,
          },
        ));
  }

  /// Logs a "checkout_started" event with the cart total and item count.
  ///
  /// Requirements: 13.3
  void logCheckoutStarted(double total, int itemCount) {
    _safeLog(() => _analytics.logEvent(
          name: 'checkout_started',
          parameters: {
            'total': total,
            'item_count': itemCount,
          },
        ));
  }

  /// Logs a "purchase_completed" event with the order total and item count.
  ///
  /// Requirements: 13.4
  void logPurchaseCompleted(double total, int itemCount) {
    _safeLog(() => _analytics.logEvent(
          name: 'purchase_completed',
          parameters: {
            'total': total,
            'item_count': itemCount,
          },
        ));
  }

  /// Logs a "search_performed" event with the search query truncated
  /// to a maximum of 256 characters.
  ///
  /// Requirements: 13.5
  void logSearch(String query) {
    final truncatedQuery = query.length > maxSearchQueryLength
        ? query.substring(0, maxSearchQueryLength)
        : query;

    _safeLog(() => _analytics.logEvent(
          name: 'search_performed',
          parameters: {
            'query': truncatedQuery,
          },
        ));
  }

  /// Sets the Firebase Analytics user ID for authenticated users.
  /// Pass null to clear the user ID on sign-out.
  ///
  /// Requirements: 13.9
  void setUserId(String? uid) {
    _safeLog(() => _analytics.setUserId(id: uid));
  }

  /// Reports an error to Firebase Crashlytics with the stack trace,
  /// anonymous user ID (set via Crashlytics user identifier), and
  /// authentication state.
  ///
  /// Never logs PII. The [fatal] parameter indicates whether the error
  /// caused a fatal crash.
  ///
  /// Requirements: 13.6
  void reportCrash(
    dynamic error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) {
    _safeLog(() async {
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: 'Unhandled exception',
      );
    });
  }

  /// Sets custom keys on Crashlytics for crash context without PII.
  void setCrashlyticsUserContext({
    required String? userId,
    required bool isAuthenticated,
  }) {
    _safeLog(() async {
      // Set anonymous user ID (Firebase UID is not PII — it's an opaque ID)
      await _crashlytics.setUserIdentifier(userId ?? 'anonymous');
      await _crashlytics.setCustomKey('is_authenticated', isAuthenticated);
    });
  }

  /// Wraps an analytics/crashlytics call in a try-catch that silently
  /// discards any failure, ensuring the user is never interrupted.
  ///
  /// Requirements: 13.8
  void _safeLog(Future<void> Function() action) {
    // Fire-and-forget: do not await, silently discard errors
    action().catchError((_) {
      // Silently discard — never interrupt the user
    });
  }
}
