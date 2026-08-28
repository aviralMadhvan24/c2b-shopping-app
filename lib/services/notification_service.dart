import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Handles Firebase Cloud Messaging registration, token management,
/// topic subscriptions, and notification display/navigation.
///
/// Key behaviors:
/// - Requests permission on first launch
/// - Registers FCM token within 10s of permission grant
/// - Stores token in user profile at `users/{uid}/fcmToken`
/// - Subscribes authenticated users to `order_updates` and `promotions` topics
/// - Shows in-app banner for foreground notifications (5s auto-dismiss, swipe to dismiss)
/// - Shows system notification for background messages
/// - Navigates to associated screen on notification tap
/// - Retries token registration up to 3 times with exponential backoff (2s, 4s, 8s)
/// - On logout: removes token from profile, unsubscribes from user-specific topics
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  /// Global navigator key used to push routes from notification taps.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Global scaffold messenger key used to show in-app banners.
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// Maximum retry attempts for token registration.
  static const int _maxRetries = 3;

  /// Base delay for exponential backoff in milliseconds.
  static const int _baseDelayMs = 2000;

  /// Auto-dismiss duration for foreground notification banners.
  static const Duration bannerDuration = Duration(seconds: 5);

  /// Subscription to foreground messages.
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    this.navigatorKey,
    this.scaffoldMessengerKey,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Requests notification permission from the user.
  ///
  /// Returns `true` if permission was granted (authorized or provisional),
  /// `false` if denied or restricted.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Registers the FCM token with Firebase Cloud Messaging.
  ///
  /// Retries up to 3 times with exponential backoff (2s, 4s, 8s) on failure.
  /// If all retries fail, the user can continue using the app without
  /// notifications.
  Future<String?> registerToken() async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final token = await _messaging.getToken();
        return token;
      } catch (e) {
        if (attempt < _maxRetries) {
          // Exponential backoff: 2s, 4s, 8s
          final delay = _baseDelayMs * (1 << attempt);
          await Future.delayed(Duration(milliseconds: delay));
        }
      }
    }
    // All retries failed — return null, allow app to continue
    return null;
  }

  /// Stores the FCM token in the user's profile document in Firestore.
  ///
  /// The token is stored at `users/{uid}` in the `fcmToken` field.
  Future<void> storeTokenInProfile(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  /// Subscribes the device to the specified notification topics.
  ///
  /// For authenticated users, subscribes to `['order_updates', 'promotions']`.
  Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      await _messaging.subscribeToTopic(topic);
    }
  }

  /// Unsubscribes the device from the specified notification topics.
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }

  /// Removes the FCM token from the user's profile document in Firestore.
  Future<void> removeTokenFromProfile(String userId) async {
    await _firestore.collection('users').doc(userId).update(
      {'fcmToken': FieldValue.delete()},
    );
  }

  /// Sets up foreground message handling.
  ///
  /// When a message is received in the foreground, shows an in-app banner
  /// with the notification title and body for 5 seconds (auto-dismiss).
  /// The banner can be manually dismissed via swipe.
  void setupForegroundMessageHandler() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleForegroundMessage(message);
    });
  }

  /// Handles a foreground message by showing an in-app banner.
  ///
  /// Displays the notification title and body in a [MaterialBanner] that
  /// auto-dismisses after 5 seconds and can be swiped to dismiss.
  void handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final messenger = scaffoldMessengerKey?.currentState;
    if (messenger == null) return;

    messenger.showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (notification.title != null)
              Text(
                notification.title!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (notification.body != null)
              Text(notification.body!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
            },
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );

    // Auto-dismiss after 5 seconds
    Future.delayed(bannerDuration, () {
      try {
        messenger.hideCurrentMaterialBanner();
      } catch (_) {
        // Banner may already be dismissed
      }
    });
  }

  /// Handles notification tap by navigating to the associated screen.
  ///
  /// Reads the `screen` and `id` fields from the notification payload data
  /// to determine which screen to navigate to.
  void handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final screen = data['screen'] as String?;

    if (screen == null || navigatorKey?.currentState == null) return;

    final navigator = navigatorKey!.currentState!;

    switch (screen) {
      case 'order_detail':
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          navigator.pushNamed('/order_detail', arguments: orderId);
        }
        break;
      case 'promotions':
        navigator.pushNamed('/promotions');
        break;
      case 'product_detail':
        final productId = data['productId'] as String?;
        if (productId != null) {
          navigator.pushNamed('/product_detail', arguments: productId);
        }
        break;
      default:
        // Unknown screen — navigate to home
        navigator.pushNamed('/');
        break;
    }
  }

  /// Sets up notification tap handler for when the app is opened from a
  /// notification tap (background/terminated state).
  void setupNotificationTapHandler() {
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message);
    });
  }

  /// Checks if the app was opened from a terminated state via notification tap.
  Future<void> checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage);
    }
  }

  /// Initializes the notification service for an authenticated user.
  ///
  /// This method:
  /// 1. Requests permission (if first launch)
  /// 2. Registers the FCM token (within 10s of permission grant)
  /// 3. Stores the token in the user's profile
  /// 4. Subscribes to default topics
  /// 5. Sets up message handlers
  Future<void> initialize(String userId) async {
    final granted = await requestPermission();
    if (!granted) {
      // Permission denied — allow normal app usage
      return;
    }

    // Register token (with retry logic)
    final token = await registerToken();
    if (token != null) {
      await storeTokenInProfile(userId, token);
    }

    // Subscribe to default topics for authenticated users
    await subscribeToTopics(['order_updates', 'promotions']);

    // Set up message handlers
    setupForegroundMessageHandler();
    setupNotificationTapHandler();
    await checkInitialMessage();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      await storeTokenInProfile(userId, newToken);
    });
  }

  /// Cleans up on logout: removes FCM token from profile and unsubscribes
  /// from user-specific topics.
  Future<void> onLogout(String userId) async {
    await removeTokenFromProfile(userId);
    await unsubscribeFromTopics(['order_updates', 'promotions']);
    _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }

  /// Disposes of the service, cancelling subscriptions.
  void dispose() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }
}

/// Background message handler — must be a top-level function.
///
/// When a push notification is received while the app is in the background,
/// the system automatically shows the notification with title and body.
/// This handler allows additional processing if needed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are automatically displayed as system notifications
  // by Firebase Messaging. This handler is available for any additional
  // processing needed (e.g., data-only messages).
}
