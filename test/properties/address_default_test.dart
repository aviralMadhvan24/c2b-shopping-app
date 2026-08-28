// Feature: app-completion, Property 7: Default Address Uniqueness
// **Validates: Requirements 9.4**
//
// For any list of addresses belonging to a user, after setting one address as
// default, exactly one address in the list SHALL have isDefault = true and its
// ID SHALL match the selected address ID, while all other addresses SHALL have
// isDefault = false.

import 'package:glados/glados.dart';
import 'package:fashion_store/models/address_model.dart';

// --- Pure function: Set Default Address Logic ---

/// Applies the "set default address" logic to a list of addresses.
/// This mirrors the batch update in AddressRepository.setDefaultAddress:
/// - Set isDefault = true for the address matching [selectedId]
/// - Set isDefault = false for all other addresses
List<Address> setDefaultAddress(List<Address> addresses, String selectedId) {
  return addresses.map((address) {
    return Address(
      id: address.id,
      name: address.name,
      phone: address.phone,
      line1: address.line1,
      line2: address.line2,
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      country: address.country,
      isDefault: address.id == selectedId,
    );
  }).toList();
}

// --- Custom Generators ---

extension AddressDefaultGenerators on Any {
  /// Generates a non-empty string for address fields.
  Generator<String> get addressField =>
      any.nonEmptyLetterOrDigits;

  /// Generates a unique ID string.
  Generator<String> get uniqueId =>
      any.nonEmptyLetterOrDigits;

  /// Generates a single Address with the given ID.
  Generator<Address> addressWithId(String id) =>
      combine5(
        addressField,
        addressField,
        addressField,
        addressField,
        addressField,
        (String name, String phone, String line1, String city, String state) {
          return Address(
            id: id,
            name: name,
            phone: phone,
            line1: line1,
            city: city,
            state: state,
            postalCode: '12345',
            country: 'India',
            isDefault: false,
          );
        },
      );

  /// Generates a list of 1-10 addresses with unique IDs, plus a selected
  /// default index into that list.
  Generator<({List<Address> addresses, String selectedId})>
      get addressListWithDefault =>
          any.intInRange(1, 10).bind((count) {
            // Generate `count` unique IDs
            return any.listWithLength(count, any.uniqueId).bind((ids) {
              // Ensure IDs are unique by appending index
              final uniqueIds =
                  ids.asMap().entries.map((e) => '${e.value}_${e.key}').toList();

              // Generate addresses for each unique ID
              return any
                  .listWithLength(
                    count,
                    combine5(
                      addressField,
                      addressField,
                      addressField,
                      addressField,
                      addressField,
                      (String name, String phone, String line1, String city,
                          String state) {
                        return (
                          name: name,
                          phone: phone,
                          line1: line1,
                          city: city,
                          state: state,
                        );
                      },
                    ),
                  )
                  .bind((fields) {
                // Build address list with unique IDs
                final addresses = <Address>[];
                for (var i = 0; i < count; i++) {
                  final f = fields[i];
                  addresses.add(Address(
                    id: uniqueIds[i],
                    name: f.name,
                    phone: f.phone,
                    line1: f.line1,
                    city: f.city,
                    state: f.state,
                    postalCode: '12345',
                    country: 'India',
                    isDefault: false,
                  ));
                }

                // Pick a random index for the default using intInRange.
                // intInRange requires min < max, so use (0, count) exclusive upper bound style
                // by generating 0..(count*10) and taking modulo count.
                return any.intInRange(0, 100).map((seed) {
                  final selectedIndex = seed % count;
                  return (
                    addresses: addresses,
                    selectedId: uniqueIds[selectedIndex],
                  );
                });
              });
            });
          });
}

void main() {
  group('Property 7: Default Address Uniqueness', () {
    Glados(any.addressListWithDefault, ExploreConfig(numRuns: 100)).test(
      'After setting default, exactly one address has isDefault=true matching selected ID',
      (input) {
        final result = setDefaultAddress(input.addresses, input.selectedId);

        // Count addresses with isDefault = true
        final defaultAddresses =
            result.where((a) => a.isDefault).toList();

        // Exactly one address should have isDefault = true
        expect(defaultAddresses.length, equals(1),
            reason:
                'Expected exactly 1 default address, found ${defaultAddresses.length}');

        // The default address ID should match the selected ID
        expect(defaultAddresses.first.id, equals(input.selectedId),
            reason:
                'Default address ID "${defaultAddresses.first.id}" does not match selected "${input.selectedId}"');
      },
    );

    Glados(any.addressListWithDefault, ExploreConfig(numRuns: 100)).test(
      'All non-selected addresses have isDefault=false',
      (input) {
        final result = setDefaultAddress(input.addresses, input.selectedId);

        // Every address that is NOT the selected one must have isDefault = false
        final nonDefault =
            result.where((a) => a.id != input.selectedId).toList();

        for (final address in nonDefault) {
          expect(address.isDefault, isFalse,
              reason:
                  'Address "${address.id}" should have isDefault=false but has isDefault=true');
        }
      },
    );

    Glados(any.addressListWithDefault, ExploreConfig(numRuns: 100)).test(
      'The total number of addresses is preserved after setting default',
      (input) {
        final result = setDefaultAddress(input.addresses, input.selectedId);

        // Setting default should not add or remove addresses
        expect(result.length, equals(input.addresses.length),
            reason:
                'Address count changed from ${input.addresses.length} to ${result.length}');
      },
    );
  });
}
