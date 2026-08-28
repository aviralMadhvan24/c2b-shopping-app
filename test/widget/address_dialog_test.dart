import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/models/address_model.dart';
import 'package:fashion_store/models/validation_result.dart';
import 'package:fashion_store/repositories/address_repository.dart';
import 'package:fashion_store/screens/address_screen.dart';
import 'package:fashion_store/theme/app_theme.dart';

/// Never touches Firestore; the screen only needs a list to render.
class _FakeAddressRepository implements AddressRepository {
  final List<Address> saved = [];

  @override
  Future<List<Address>> fetchAddresses(String userId) async => saved;

  @override
  Future<void> saveAddress(String userId, Address address) async {
    saved.add(address);
  }

  @override
  Future<void> deleteAddress(String userId, String addressId) async {
    saved.removeWhere((a) => a.id == addressId);
  }

  @override
  Future<void> setDefaultAddress(String userId, String addressId) async {}

  @override
  ValidationResult validateAddress(Address address) =>
      const ValidationResult(isValid: true, fieldErrors: {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets(
    'opening the add-address dialog lays out without throwing',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final user = _MockUser();
      when(() => user.uid).thenReturn('test-uid');

      await tester.pumpWidget(
        MaterialApp(
          // The real theme matters here: its ElevatedButton minimumSize is
          // what forced an infinite width and hung the app.
          theme: AppTheme.darkTheme,
          home: AddressScreen(
            addressRepository: _FakeAddressRepository(),
            currentUser: user,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsWidgets, reason: 'add-address entry point');

      await tester.tap(addButton.first);
      await tester.pumpAndSettle();

      // Before the fix this threw "BoxConstraints forces an infinite width"
      // on every layout pass, which locked up the running app.
      expect(tester.takeException(), isNull);
      expect(find.text('Add Address'), findsWidgets);
    },
  );
}
