// Mocking cloud_firestore's sealed Query/DocumentReference/DocumentSnapshot types is the
// only way to unit test this code without a live Firestore instance.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/providers/wishlist_provider.dart';

// --- Mocks ---

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
    registerFallbackValue(<String, dynamic>{});
  });
  group('WishlistNotifier - guest mode', () {
    late WishlistNotifier notifier;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      notifier = WishlistNotifier(firestore: mockFirestore, userId: null);
    });

    test('addItem stores product ID and timestamp', () async {
      await notifier.addItem('prod-1');

      final state = notifier.state;
      expect(state.items.length, 1);
      expect(state.items.containsKey('prod-1'), isTrue);

      final item = state.items['prod-1']!;
      expect(item.productId, 'prod-1');
      expect(item.addedAt, isA<DateTime>());
      // Timestamp should be recent (within last 5 seconds)
      expect(
        DateTime.now().difference(item.addedAt).inSeconds,
        lessThan(5),
      );
    });

    test('addItem skips duplicate product IDs', () async {
      await notifier.addItem('prod-1');
      await notifier.addItem('prod-1');

      final state = notifier.state;
      expect(state.items.length, 1);
    });

    test('removeItem deletes entry', () async {
      await notifier.addItem('prod-1');
      await notifier.addItem('prod-2');

      await notifier.removeItem('prod-1');

      final state = notifier.state;
      expect(state.items.length, 1);
      expect(state.items.containsKey('prod-1'), isFalse);
      expect(state.items.containsKey('prod-2'), isTrue);
    });
  });

  group('WishlistNotifier - mergeLocalItems', () {
    late WishlistNotifier notifier;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockUsersCollection;
    late MockDocumentReference mockUserDoc;
    late MockCollectionReference mockWishlistCollection;
    late MockQuerySnapshot mockQuerySnapshot;
    late MockWriteBatch mockBatch;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();
      mockWishlistCollection = MockCollectionReference();
      mockQuerySnapshot = MockQuerySnapshot();
      mockBatch = MockWriteBatch();

      // Wire up Firestore collection chain: firestore.collection('users').doc(uid).collection('wishlist')
      when(() => mockFirestore.collection('users'))
          .thenReturn(mockUsersCollection);
      when(() => mockUsersCollection.doc('test-user'))
          .thenReturn(mockUserDoc);
      when(() => mockUserDoc.collection('wishlist'))
          .thenReturn(mockWishlistCollection);
      when(() => mockFirestore.batch()).thenReturn(mockBatch);
    });

    test('merge adds only non-duplicate product IDs', () async {
      // Create notifier as guest first to add local items
      final guestNotifier = WishlistNotifier(
        firestore: mockFirestore,
        userId: null,
      );
      await guestNotifier.addItem('local-1');
      await guestNotifier.addItem('local-2');
      await guestNotifier.addItem('shared-1'); // This one already exists remotely

      // Now create authenticated notifier with pre-existing local items
      notifier = WishlistNotifier(
        firestore: mockFirestore,
        userId: 'test-user',
      );

      // Manually set local state to simulate items from guest session
      await notifier.addItem('local-1');
      await notifier.addItem('local-2');
      await notifier.addItem('shared-1');

      // Mock Firestore already having 'shared-1' and 'remote-1'
      final mockRemoteDoc1 = MockQueryDocumentSnapshot();
      when(() => mockRemoteDoc1.data()).thenReturn({
        'productId': 'shared-1',
        'addedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final mockRemoteDoc2 = MockQueryDocumentSnapshot();
      when(() => mockRemoteDoc2.data()).thenReturn({
        'productId': 'remote-1',
        'addedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      });

      when(() => mockQuerySnapshot.docs)
          .thenReturn([mockRemoteDoc1, mockRemoteDoc2]);

      when(() => mockWishlistCollection.get())
          .thenAnswer((_) async => mockQuerySnapshot);

      // Mock document references for batch.set calls
      final mockLocalDoc1Ref = MockDocumentReference();
      final mockLocalDoc2Ref = MockDocumentReference();
      when(() => mockWishlistCollection.doc('local-1'))
          .thenReturn(mockLocalDoc1Ref);
      when(() => mockWishlistCollection.doc('local-2'))
          .thenReturn(mockLocalDoc2Ref);
      when(() => mockWishlistCollection.doc('shared-1'))
          .thenReturn(MockDocumentReference());

      when(() => mockBatch.set<Map<String, dynamic>>(any(), any()))
          .thenReturn(null);
      when(() => mockBatch.commit()).thenAnswer((_) async {});

      // Perform merge
      await notifier.mergeLocalItems();

      final state = notifier.state;

      // Should contain: remote-1, shared-1 (from remote), local-1, local-2
      expect(state.items.length, 4);
      expect(state.items.containsKey('local-1'), isTrue);
      expect(state.items.containsKey('local-2'), isTrue);
      expect(state.items.containsKey('shared-1'), isTrue);
      expect(state.items.containsKey('remote-1'), isTrue);

      // Verify batch.set was called exactly 2 times (local-1 and local-2, not shared-1)
      verify(() => mockBatch.set<Map<String, dynamic>>(any(), any())).called(2);
      verify(() => mockBatch.commit()).called(1);
    });
  });
}
