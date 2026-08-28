// Mocking cloud_firestore's sealed Query/DocumentReference/DocumentSnapshot types is the
// only way to unit test this code without a live Firestore instance.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/services/notification_service.dart';

// --- Mocks ---

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

void main() {
  late NotificationService service;
  late MockFirebaseMessaging mockMessaging;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();

    // Wire up Firestore chain: firestore.collection('users').doc(userId)
    when(() => mockFirestore.collection('users'))
        .thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);

    service = NotificationService(
      messaging: mockMessaging,
      firestore: mockFirestore,
    );
  });

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(SetOptions(merge: true));
  });

  group('NotificationService - requestPermission', () {
    test('returns true when authorization status is authorized', () async {
      final mockSettings = MockNotificationSettings();
      when(() => mockSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.authorized);
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
          )).thenAnswer((_) async => mockSettings);

      final result = await service.requestPermission();

      expect(result, isTrue);
      verify(() => mockMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          )).called(1);
    });

    test('returns true when authorization status is provisional', () async {
      final mockSettings = MockNotificationSettings();
      when(() => mockSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.provisional);
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
          )).thenAnswer((_) async => mockSettings);

      final result = await service.requestPermission();

      expect(result, isTrue);
    });

    test('returns false when authorization status is denied', () async {
      final mockSettings = MockNotificationSettings();
      when(() => mockSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.denied);
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
          )).thenAnswer((_) async => mockSettings);

      final result = await service.requestPermission();

      expect(result, isFalse);
    });

    test('returns false when authorization status is notDetermined', () async {
      final mockSettings = MockNotificationSettings();
      when(() => mockSettings.authorizationStatus)
          .thenReturn(AuthorizationStatus.notDetermined);
      when(() => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
            provisional: any(named: 'provisional'),
          )).thenAnswer((_) async => mockSettings);

      final result = await service.requestPermission();

      expect(result, isFalse);
    });
  });

  group('NotificationService - registerToken (retry logic)', () {
    test('returns token on first successful attempt', () async {
      when(() => mockMessaging.getToken())
          .thenAnswer((_) async => 'test-fcm-token');

      final token = await service.registerToken();

      expect(token, 'test-fcm-token');
      verify(() => mockMessaging.getToken()).called(1);
    });

    test('retries on failure and returns token on subsequent success',
        () async {
      int callCount = 0;
      when(() => mockMessaging.getToken()).thenAnswer((_) async {
        callCount++;
        if (callCount < 3) {
          throw Exception('Network error');
        }
        return 'recovered-token';
      });

      final token = await service.registerToken();

      expect(token, 'recovered-token');
      // Should have been called 3 times (2 failures + 1 success)
      verify(() => mockMessaging.getToken()).called(3);
    });

    test('returns null when all retries fail', () async {
      when(() => mockMessaging.getToken())
          .thenThrow(Exception('Persistent failure'));

      final token = await service.registerToken();

      expect(token, isNull);
      // Initial attempt + 3 retries = 4 calls total
      verify(() => mockMessaging.getToken()).called(4);
    });
  });

  group('NotificationService - onLogout', () {
    test('removes token from profile and unsubscribes from topics', () async {
      when(() => mockUserDoc.update(any())).thenAnswer((_) async {});
      when(() => mockMessaging.unsubscribeFromTopic(any()))
          .thenAnswer((_) async {});

      await service.onLogout('user-123');

      // Verify token removal from Firestore
      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUsersCollection.doc('user-123')).called(1);
      verify(() => mockUserDoc.update({'fcmToken': FieldValue.delete()}))
          .called(1);

      // Verify unsubscription from both topics
      verify(() => mockMessaging.unsubscribeFromTopic('order_updates'))
          .called(1);
      verify(() => mockMessaging.unsubscribeFromTopic('promotions')).called(1);
    });

    test('unsubscribes from order_updates topic', () async {
      when(() => mockUserDoc.update(any())).thenAnswer((_) async {});
      when(() => mockMessaging.unsubscribeFromTopic(any()))
          .thenAnswer((_) async {});

      await service.onLogout('user-abc');

      verify(() => mockMessaging.unsubscribeFromTopic('order_updates'))
          .called(1);
    });

    test('unsubscribes from promotions topic', () async {
      when(() => mockUserDoc.update(any())).thenAnswer((_) async {});
      when(() => mockMessaging.unsubscribeFromTopic(any()))
          .thenAnswer((_) async {});

      await service.onLogout('user-abc');

      verify(() => mockMessaging.unsubscribeFromTopic('promotions')).called(1);
    });
  });

  group('NotificationService - storeTokenInProfile', () {
    test('stores FCM token in user profile document', () async {
      when(() => mockUserDoc.set(any(), any())).thenAnswer((_) async {});

      await service.storeTokenInProfile('user-123', 'my-fcm-token');

      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUsersCollection.doc('user-123')).called(1);
      verify(() => mockUserDoc.set(
            {'fcmToken': 'my-fcm-token'},
            any(that: isA<SetOptions>()),
          )).called(1);
    });
  });
}
