import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/address_model.dart';
import '../models/validation_result.dart';

/// Repository for managing saved addresses in Cloud Firestore.
///
/// Addresses are stored at: users/{uid}/addresses/{addressId}
class AddressRepository {
  final FirebaseFirestore _firestore;

  /// Maximum number of addresses a user can store.
  static const int maxAddresses = 10;

  /// Max lengths for each field.
  static const int maxNameLength = 100;
  static const int maxPhoneLength = 20;
  static const int maxLine1Length = 200;
  static const int maxCityLength = 100;
  static const int maxStateLength = 100;
  static const int maxPostalCodeLength = 20;
  static const int maxCountryLength = 100;

  AddressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches all addresses for a user.
  Future<List<Address>> fetchAddresses(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .get();

    return snapshot.docs
        .map((doc) => Address.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Saves a new or updated address for a user.
  ///
  /// Validates the address before saving. Enforces max 10 addresses per user.
  /// If the address has an empty id, a new document is created.
  /// Otherwise the existing document is overwritten.
  Future<void> saveAddress(String userId, Address address) async {
    final validation = validateAddress(address);
    if (!validation.isValid) {
      throw AddressValidationException(validation);
    }

    final addressesRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('addresses');

    // Enforce max 10 addresses (only check when adding new)
    if (address.id.isEmpty) {
      final snapshot = await addressesRef.get();
      if (snapshot.docs.length >= maxAddresses) {
        throw AddressLimitException();
      }
      // Create new document
      final docRef = addressesRef.doc();
      final data = address.toMap();
      data.remove('id');
      await docRef.set(data);
    } else {
      // Update existing
      final data = address.toMap();
      data.remove('id');
      await addressesRef.doc(address.id).set(data);
    }
  }

  /// Deletes an address by ID.
  ///
  /// If the deleted address is the default, clears `defaultAddressId` on the user profile.
  Future<void> deleteAddress(String userId, String addressId) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final userDoc = await userDocRef.get();
    final defaultAddressId = userDoc.data()?['defaultAddressId'] as String?;

    await userDocRef.collection('addresses').doc(addressId).delete();

    // If deleted address was the default, clear defaultAddressId
    if (defaultAddressId == addressId) {
      await userDocRef.update({'defaultAddressId': null});
    }
  }

  /// Sets an address as the default.
  ///
  /// Updates `defaultAddressId` on the user profile document
  /// and sets `isDefault = false` on all other addresses.
  Future<void> setDefaultAddress(String userId, String addressId) async {
    final userDocRef = _firestore.collection('users').doc(userId);
    final addressesRef = userDocRef.collection('addresses');

    // Update all addresses to isDefault = false
    final snapshot = await addressesRef.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }

    // Update user profile with the default address id
    batch.update(userDocRef, {'defaultAddressId': addressId});
    await batch.commit();
  }

  /// Validates an address, returning a [ValidationResult].
  ///
  /// All required fields must be non-empty after trimming whitespace
  /// and must not exceed their maximum length.
  ValidationResult validateAddress(Address address) {
    final errors = <String, String>{};

    _validateField(errors, 'name', address.name, maxNameLength);
    _validateField(errors, 'phone', address.phone, maxPhoneLength);
    _validateField(errors, 'line1', address.line1, maxLine1Length);
    _validateField(errors, 'city', address.city, maxCityLength);
    _validateField(errors, 'state', address.state, maxStateLength);
    _validateField(errors, 'postalCode', address.postalCode, maxPostalCodeLength);
    _validateField(errors, 'country', address.country, maxCountryLength);

    if (errors.isEmpty) {
      return ValidationResult.valid();
    }
    return ValidationResult.invalid(errors);
  }

  void _validateField(
    Map<String, String> errors,
    String fieldName,
    String value,
    int maxLength,
  ) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      errors[fieldName] = '$fieldName is required';
    } else if (trimmed.length > maxLength) {
      errors[fieldName] = '$fieldName must be at most $maxLength characters';
    }
  }
}

/// Thrown when address validation fails.
class AddressValidationException implements Exception {
  final ValidationResult validationResult;

  AddressValidationException(this.validationResult);

  @override
  String toString() =>
      'AddressValidationException: ${validationResult.fieldErrors}';
}

/// Thrown when the maximum address limit (10) has been reached.
class AddressLimitException implements Exception {
  @override
  String toString() =>
      'Maximum of ${AddressRepository.maxAddresses} addresses reached.';
}
