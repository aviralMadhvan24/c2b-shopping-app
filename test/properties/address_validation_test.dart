// Feature: app-completion, Property 6: Address Validation
// **Validates: Requirements 9.2, 9.3**
//
// For any address where any required field is empty after trimming whitespace
// OR exceeds its maximum character length (name: 100, phone: 20, line1: 200,
// city: 100, state: 100, postalCode: 20, country: 100), validation SHALL
// reject. For valid addresses, validation SHALL accept.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' hide any;
import 'package:fashion_store/repositories/address_repository.dart';
import 'package:fashion_store/models/address_model.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// --- Constants matching AddressRepository ---
const int maxNameLength = 100;
const int maxPhoneLength = 20;
const int maxLine1Length = 200;
const int maxCityLength = 100;
const int maxStateLength = 100;
const int maxPostalCodeLength = 20;
const int maxCountryLength = 100;

// --- Custom Generators ---

extension AddressValidationGenerators on Any {
  /// Generates a non-empty string within the given max length using letterOrDigits.
  Generator<String> validField(int maxLength) {
    // Generate a string of length 1..maxLength
    return intInRange(1, maxLength).map((len) => 'a' * len);
  }

  /// Generates a string that exceeds the given max length.
  Generator<String> overLengthField(int maxLength) {
    return intInRange(maxLength + 1, maxLength + 50).map((len) => 'x' * len);
  }

  /// Generates a string that is empty or only whitespace.
  Generator<String> get emptyOrWhitespaceField =>
      choose(['', ' ', '  ', '\t', '\n', '   \t\n  ']);
}

/// Helper to create a valid address with all fields within limits.
Address _validAddress({
  String name = 'John Doe',
  String phone = '1234567890',
  String line1 = '123 Main Street',
  String city = 'Springfield',
  String state = 'Illinois',
  String postalCode = '62701',
  String country = 'US',
}) {
  return Address(
    id: 'test-id',
    name: name,
    phone: phone,
    line1: line1,
    city: city,
    state: state,
    postalCode: postalCode,
    country: country,
  );
}

void main() {
  final repo = AddressRepository(firestore: MockFirebaseFirestore());

  group('Property 6: Address Validation', () {
    // --- Valid addresses should be accepted ---

    Glados(any.validField(maxNameLength), ExploreConfig(numRuns: 100)).test(
      'Valid addresses with all fields non-empty and within limits are accepted',
      (name) {
        final address = _validAddress(name: name);
        final result = repo.validateAddress(address);
        expect(result.isValid, isTrue,
            reason: 'Address with valid name of length ${name.length} should be accepted');
      },
    );

    Glados3(
      any.validField(maxPhoneLength),
      any.validField(maxLine1Length),
      any.validField(maxCityLength),
      ExploreConfig(numRuns: 100),
    ).test(
      'Valid addresses with various valid phone, line1, city are accepted',
      (phone, line1, city) {
        final address = _validAddress(phone: phone, line1: line1, city: city);
        final result = repo.validateAddress(address);
        expect(result.isValid, isTrue,
            reason: 'Address with valid phone/line1/city should be accepted');
      },
    );

    Glados3(
      any.validField(maxStateLength),
      any.validField(maxPostalCodeLength),
      any.validField(maxCountryLength),
      ExploreConfig(numRuns: 100),
    ).test(
      'Valid addresses with various valid state, postalCode, country are accepted',
      (state, postalCode, country) {
        final address =
            _validAddress(state: state, postalCode: postalCode, country: country);
        final result = repo.validateAddress(address);
        expect(result.isValid, isTrue,
            reason: 'Address with valid state/postalCode/country should be accepted');
      },
    );

    // --- Empty/whitespace fields should be rejected ---

    Glados(any.emptyOrWhitespaceField, ExploreConfig(numRuns: 100)).test(
      'Address with empty/whitespace name is rejected',
      (name) {
        final address = _validAddress(name: name);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Name "$name" (empty/whitespace) should be rejected');
        expect(result.fieldErrors.containsKey('name'), isTrue);
      },
    );

    Glados(any.emptyOrWhitespaceField, ExploreConfig(numRuns: 100)).test(
      'Address with empty/whitespace phone is rejected',
      (phone) {
        final address = _validAddress(phone: phone);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Phone "$phone" (empty/whitespace) should be rejected');
        expect(result.fieldErrors.containsKey('phone'), isTrue);
      },
    );

    Glados(any.emptyOrWhitespaceField, ExploreConfig(numRuns: 100)).test(
      'Address with empty/whitespace line1 is rejected',
      (line1) {
        final address = _validAddress(line1: line1);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Line1 "$line1" (empty/whitespace) should be rejected');
        expect(result.fieldErrors.containsKey('line1'), isTrue);
      },
    );

    Glados(any.emptyOrWhitespaceField, ExploreConfig(numRuns: 100)).test(
      'Address with empty/whitespace city is rejected',
      (city) {
        final address = _validAddress(city: city);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'City "$city" (empty/whitespace) should be rejected');
        expect(result.fieldErrors.containsKey('city'), isTrue);
      },
    );

    Glados(any.emptyOrWhitespaceField, ExploreConfig(numRuns: 100)).test(
      'Address with empty/whitespace state is rejected',
      (state) {
        final address = _validAddress(state: state);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'State "$state" (empty/whitespace) should be rejected');
        expect(result.fieldErrors.containsKey('state'), isTrue);
      },
    );

    Glados(any.emptyOrWhitespaceField, ExploreConfig(numRuns: 100)).test(
      'Address with empty/whitespace postalCode is rejected',
      (postalCode) {
        final address = _validAddress(postalCode: postalCode);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'PostalCode "$postalCode" (empty/whitespace) should be rejected');
        expect(result.fieldErrors.containsKey('postalCode'), isTrue);
      },
    );

    Glados(any.emptyOrWhitespaceField, ExploreConfig(numRuns: 100)).test(
      'Address with empty/whitespace country is rejected',
      (country) {
        final address = _validAddress(country: country);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Country "$country" (empty/whitespace) should be rejected');
        expect(result.fieldErrors.containsKey('country'), isTrue);
      },
    );

    // --- Over-length fields should be rejected ---

    Glados(any.overLengthField(maxNameLength), ExploreConfig(numRuns: 100)).test(
      'Address with over-length name is rejected',
      (name) {
        final address = _validAddress(name: name);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Name of length ${name.length} (> $maxNameLength) should be rejected');
        expect(result.fieldErrors.containsKey('name'), isTrue);
      },
    );

    Glados(any.overLengthField(maxPhoneLength), ExploreConfig(numRuns: 100)).test(
      'Address with over-length phone is rejected',
      (phone) {
        final address = _validAddress(phone: phone);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Phone of length ${phone.length} (> $maxPhoneLength) should be rejected');
        expect(result.fieldErrors.containsKey('phone'), isTrue);
      },
    );

    Glados(any.overLengthField(maxLine1Length), ExploreConfig(numRuns: 100)).test(
      'Address with over-length line1 is rejected',
      (line1) {
        final address = _validAddress(line1: line1);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Line1 of length ${line1.length} (> $maxLine1Length) should be rejected');
        expect(result.fieldErrors.containsKey('line1'), isTrue);
      },
    );

    Glados(any.overLengthField(maxCityLength), ExploreConfig(numRuns: 100)).test(
      'Address with over-length city is rejected',
      (city) {
        final address = _validAddress(city: city);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'City of length ${city.length} (> $maxCityLength) should be rejected');
        expect(result.fieldErrors.containsKey('city'), isTrue);
      },
    );

    Glados(any.overLengthField(maxStateLength), ExploreConfig(numRuns: 100)).test(
      'Address with over-length state is rejected',
      (state) {
        final address = _validAddress(state: state);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'State of length ${state.length} (> $maxStateLength) should be rejected');
        expect(result.fieldErrors.containsKey('state'), isTrue);
      },
    );

    Glados(any.overLengthField(maxPostalCodeLength), ExploreConfig(numRuns: 100))
        .test(
      'Address with over-length postalCode is rejected',
      (postalCode) {
        final address = _validAddress(postalCode: postalCode);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'PostalCode of length ${postalCode.length} (> $maxPostalCodeLength) should be rejected');
        expect(result.fieldErrors.containsKey('postalCode'), isTrue);
      },
    );

    Glados(any.overLengthField(maxCountryLength), ExploreConfig(numRuns: 100))
        .test(
      'Address with over-length country is rejected',
      (country) {
        final address = _validAddress(country: country);
        final result = repo.validateAddress(address);
        expect(result.isValid, isFalse,
            reason: 'Country of length ${country.length} (> $maxCountryLength) should be rejected');
        expect(result.fieldErrors.containsKey('country'), isTrue);
      },
    );
  });
}
