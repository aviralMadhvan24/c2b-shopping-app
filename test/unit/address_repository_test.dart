// Mocking cloud_firestore's sealed Query/DocumentReference/DocumentSnapshot types is the
// only way to unit test this code without a live Firestore instance.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/models/address_model.dart';
import 'package:fashion_store/repositories/address_repository.dart';

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

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

// --- Helpers ---

Address _validAddress({String id = '', bool isDefault = false}) {
  return Address(
    id: id,
    name: 'John Doe',
    phone: '1234567890',
    line1: '123 Main St',
    city: 'Springfield',
    state: 'IL',
    postalCode: '62701',
    country: 'USA',
    isDefault: isDefault,
  );
}

Address _invalidAddress() {
  return const Address(
    id: '',
    name: '',
    phone: '',
    line1: '',
    city: '',
    state: '',
    postalCode: '',
    country: '',
  );
}

void main() {
  late AddressRepository repository;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDoc;
  late MockCollectionReference mockAddressesCollection;

  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockAddressesCollection = MockCollectionReference();

    when(() => mockFirestore.collection('users'))
        .thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);
    when(() => mockUserDoc.collection('addresses'))
        .thenReturn(mockAddressesCollection);

    repository = AddressRepository(firestore: mockFirestore);
  });

  group('AddressRepository', () {
    group('saveAddress', () {
      test('succeeds for a valid new address', () async {
        final address = _validAddress();
        final mockNewDocRef = MockDocumentReference();
        final mockSnapshot = MockQuerySnapshot();

        when(() => mockAddressesCollection.get())
            .thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([]);
        when(() => mockAddressesCollection.doc()).thenReturn(mockNewDocRef);
        when(() => mockNewDocRef.set(any())).thenAnswer((_) async {});

        await repository.saveAddress('user-1', address);

        verify(() => mockNewDocRef.set(any())).called(1);
      });

      test('throws AddressValidationException for invalid address', () async {
        final address = _invalidAddress();

        expect(
          () => repository.saveAddress('user-1', address),
          throwsA(isA<AddressValidationException>()),
        );
      });

      test('throws AddressLimitException when 10 addresses exist', () async {
        final address = _validAddress(); // id is empty → new address
        final mockSnapshot = MockQuerySnapshot();

        // Create 10 mock documents to simulate existing addresses
        final mockDocs = List.generate(10, (i) {
          final doc = MockQueryDocumentSnapshot();
          when(() => doc.id).thenReturn('addr-$i');
          return doc;
        });

        when(() => mockAddressesCollection.get())
            .thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn(mockDocs);

        expect(
          () => repository.saveAddress('user-1', address),
          throwsA(isA<AddressLimitException>()),
        );
      });
    });

    group('deleteAddress', () {
      test('removes address document from Firestore', () async {
        final mockAddrDocRef = MockDocumentReference();
        final mockUserDocSnapshot = MockDocumentSnapshot();

        when(() => mockUserDoc.get())
            .thenAnswer((_) async => mockUserDocSnapshot);
        when(() => mockUserDocSnapshot.data())
            .thenReturn({'defaultAddressId': 'other-addr'});
        when(() => mockAddressesCollection.doc('addr-1'))
            .thenReturn(mockAddrDocRef);
        when(() => mockAddrDocRef.delete()).thenAnswer((_) async {});

        await repository.deleteAddress('user-1', 'addr-1');

        verify(() => mockAddrDocRef.delete()).called(1);
        // Should NOT clear defaultAddressId since it's a different address
        verifyNever(() => mockUserDoc.update(any()));
      });

      test('clears defaultAddressId when deleting the default address',
          () async {
        final mockAddrDocRef = MockDocumentReference();
        final mockUserDocSnapshot = MockDocumentSnapshot();

        when(() => mockUserDoc.get())
            .thenAnswer((_) async => mockUserDocSnapshot);
        when(() => mockUserDocSnapshot.data())
            .thenReturn({'defaultAddressId': 'addr-1'});
        when(() => mockAddressesCollection.doc('addr-1'))
            .thenReturn(mockAddrDocRef);
        when(() => mockAddrDocRef.delete()).thenAnswer((_) async {});
        when(() => mockUserDoc.update(any())).thenAnswer((_) async {});

        await repository.deleteAddress('user-1', 'addr-1');

        verify(() => mockAddrDocRef.delete()).called(1);
        verify(() => mockUserDoc.update({'defaultAddressId': null})).called(1);
      });
    });

    group('setDefaultAddress', () {
      test('sets isDefault=true on target and false on others', () async {
        final mockBatch = MockWriteBatch();
        final mockSnapshot = MockQuerySnapshot();

        final doc1 = MockQueryDocumentSnapshot();
        final doc1Ref = MockDocumentReference();
        when(() => doc1.id).thenReturn('addr-1');
        when(() => doc1.reference).thenReturn(doc1Ref);

        final doc2 = MockQueryDocumentSnapshot();
        final doc2Ref = MockDocumentReference();
        when(() => doc2.id).thenReturn('addr-2');
        when(() => doc2.reference).thenReturn(doc2Ref);

        final doc3 = MockQueryDocumentSnapshot();
        final doc3Ref = MockDocumentReference();
        when(() => doc3.id).thenReturn('addr-3');
        when(() => doc3.reference).thenReturn(doc3Ref);

        when(() => mockFirestore.batch()).thenReturn(mockBatch);
        when(() => mockAddressesCollection.get())
            .thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.docs).thenReturn([doc1, doc2, doc3]);
        when(() => mockBatch.update(any(), any())).thenReturn(null);
        when(() => mockBatch.commit()).thenAnswer((_) async {});

        await repository.setDefaultAddress('user-1', 'addr-2');

        // addr-2 should be set to true, others to false
        verify(() => mockBatch.update(doc1Ref, {'isDefault': false})).called(1);
        verify(() => mockBatch.update(doc2Ref, {'isDefault': true})).called(1);
        verify(() => mockBatch.update(doc3Ref, {'isDefault': false})).called(1);

        // User profile should be updated with defaultAddressId
        verify(() =>
                mockBatch.update(mockUserDoc, {'defaultAddressId': 'addr-2'}))
            .called(1);

        verify(() => mockBatch.commit()).called(1);
      });
    });
  });
}
