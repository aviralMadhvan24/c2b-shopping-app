// Feature: app-completion, Property 9: Pre-Select First Available Variant
// **Validates: Requirements 5.2**
//
// For any non-empty list of product variants, the pre-selected variant SHALL be
// the first variant in list order where availableForSale is true. If no variant
// is available for sale, the pre-selected variant SHALL be the first variant in
// the list.

import 'package:glados/glados.dart';
import 'package:fashion_store/models/product_model.dart';
import 'package:fashion_store/widgets/variant_selector.dart';

// --- Custom Generators ---

extension VariantPreselectGenerators on Any {
  /// Generates a ProductVariant with random availability.
  Generator<ProductVariant> get productVariant => combine3(
        nonEmptyLetterOrDigits,
        doubleInRange(1.0, 999.0),
        choose([true, false]),
        (String id, double price, bool available) => ProductVariant(
          id: id,
          title: 'Variant $id',
          price: (price * 100).round() / 100.0,
          currencyCode: 'USD',
          availableForSale: available,
          selectedOptions: {'Size': id},
        ),
      );

  /// Generates a non-empty list of ProductVariants (1 to 10 items).
  Generator<List<ProductVariant>> get nonEmptyVariantList =>
      listWithLengthInRange(1, 10, any.productVariant);
}

void main() {
  group('Property 9: Pre-Select First Available Variant', () {
    Glados(any.nonEmptyVariantList, ExploreConfig(numRuns: 100)).test(
      'Pre-selects first available-for-sale variant in list order',
      (variants) {
        final result = preselectVariant(variants);

        // Result should never be null for non-empty lists
        expect(result, isNotNull);

        // Find the expected variant: first with availableForSale == true
        ProductVariant? expectedFirstAvailable;
        for (final variant in variants) {
          if (variant.availableForSale) {
            expectedFirstAvailable = variant;
            break;
          }
        }

        if (expectedFirstAvailable != null) {
          // Should select the first available variant
          expect(result, equals(expectedFirstAvailable));
        } else {
          // No available variant — should select the first in the list
          expect(result, equals(variants.first));
        }
      },
    );

    Glados(
      any.listWithLengthInRange(1, 10, any.nonEmptyLetterOrDigits),
      ExploreConfig(numRuns: 100),
    ).test(
      'When all variants are unavailable, selects first variant in list',
      (ids) {
        final variants = ids
            .map((id) => ProductVariant(
                  id: id,
                  title: 'Variant $id',
                  price: 10.0,
                  availableForSale: false,
                  selectedOptions: {'Size': id},
                ))
            .toList();

        final result = preselectVariant(variants);

        expect(result, isNotNull);
        expect(result, equals(variants.first));
      },
    );

    Glados(
      any.listWithLengthInRange(1, 10, any.nonEmptyLetterOrDigits),
      ExploreConfig(numRuns: 100),
    ).test(
      'When all variants are available, selects first variant in list',
      (ids) {
        final variants = ids
            .map((id) => ProductVariant(
                  id: id,
                  title: 'Variant $id',
                  price: 10.0,
                  availableForSale: true,
                  selectedOptions: {'Size': id},
                ))
            .toList();

        final result = preselectVariant(variants);

        expect(result, isNotNull);
        expect(result, equals(variants.first));
      },
    );
  });
}
