// Feature: app-completion, Property 8: Variant Resolution From Selected Options
// **Validates: Requirements 5.3, 5.4**
//
// For any product with variants and any combination of selected options (one per
// option group), the resolved variant SHALL be the variant whose selectedOptions
// map matches all the currently selected option values. If no variant matches the
// full combination, the resolution SHALL return null.

import 'package:glados/glados.dart';
import 'package:fashion_store/models/product_model.dart';
import 'package:fashion_store/widgets/variant_selector.dart';

// --- Custom Generators ---

extension VariantResolutionGenerators on Any {
  /// Generates a scenario where a matching variant exists.
  /// Creates 1-5 variants with different option combinations using 1-2 option
  /// groups, then selects one variant's options as the "selected" options.
  Generator<({List<ProductVariant> variants, Map<String, String> selected})>
      get matchingScenario => combine5(
            any.nonEmptyLetterOrDigits, // group1 name
            any.nonEmptyLetterOrDigits, // group2 name
            any.listWithLengthInRange(
                2, 4, any.nonEmptyLetterOrDigits), // group1 values
            any.listWithLengthInRange(
                2, 4, any.nonEmptyLetterOrDigits), // group2 values
            any.intInRange(2, 5), // variant count
            (String group1Name, String group2Name, List<String> group1Values,
                List<String> group2Values, int variantCount) {
              final variants = <ProductVariant>[];

              for (var i = 0; i < variantCount; i++) {
                final v1 = group1Values[i % group1Values.length];
                final v2 = group2Values[i % group2Values.length];
                variants.add(ProductVariant(
                  id: 'variant_$i',
                  title: 'Variant $i',
                  price: 10.0 + i,
                  availableForSale: true,
                  selectedOptions: {group1Name: v1, group2Name: v2},
                ));
              }

              // Pick the middle variant's options as the selected combination
              final targetIndex = variantCount ~/ 2;
              final selected = Map<String, String>.from(
                  variants[targetIndex].selectedOptions);

              return (variants: variants, selected: selected);
            },
          );

  /// Generates a scenario where NO variant matches the selected options.
  /// Creates variants with specific option values, then selects an option
  /// combination that uses a unique suffix to guarantee no match.
  Generator<({List<ProductVariant> variants, Map<String, String> selected})>
      get nonMatchingScenario => combine5(
            any.nonEmptyLetterOrDigits, // group1 name
            any.nonEmptyLetterOrDigits, // group2 name
            any.listWithLengthInRange(
                2, 4, any.nonEmptyLetterOrDigits), // group1 values
            any.listWithLengthInRange(
                2, 4, any.nonEmptyLetterOrDigits), // group2 values
            any.intInRange(1, 5), // variant count
            (String group1Name, String group2Name, List<String> group1Values,
                List<String> group2Values, int variantCount) {
              final variants = <ProductVariant>[];

              for (var i = 0; i < variantCount; i++) {
                final v1 = group1Values[i % group1Values.length];
                final v2 = group2Values[i % group2Values.length];
                variants.add(ProductVariant(
                  id: 'variant_$i',
                  title: 'Variant $i',
                  price: 10.0 + i,
                  availableForSale: true,
                  selectedOptions: {group1Name: v1, group2Name: v2},
                ));
              }

              // Use a value that cannot match any variant by appending a unique
              // suffix. This guarantees no variant has this exact combination.
              final selected = <String, String>{
                group1Name: '${group1Values.first}_NOMATCH',
                group2Name: '${group2Values.first}_NOMATCH',
              };

              return (variants: variants, selected: selected);
            },
          );
}

void main() {
  group('Property 8: Variant Resolution From Selected Options', () {
    Glados(any.matchingScenario, ExploreConfig(numRuns: 100)).test(
      'Resolved variant matches selected options combination',
      (scenario) {
        final result = resolveVariant(
          scenario.variants,
          scenario.selected,
        );

        // A match must be found
        expect(result, isNotNull,
            reason: 'Expected a matching variant for selected options '
                '${scenario.selected}');

        // The returned variant's selectedOptions must match all selected values
        for (final entry in scenario.selected.entries) {
          expect(result!.selectedOptions[entry.key], equals(entry.value),
              reason:
                  'Variant option "${entry.key}" should be "${entry.value}" '
                  'but was "${result.selectedOptions[entry.key]}"');
        }
      },
    );

    Glados(any.nonMatchingScenario, ExploreConfig(numRuns: 100)).test(
      'Returns null when no variant matches selected options',
      (scenario) {
        final result = resolveVariant(
          scenario.variants,
          scenario.selected,
        );

        // No match should be found
        expect(result, isNull,
            reason: 'Expected null for non-matching options '
                '${scenario.selected} but got variant ${result?.id}');
      },
    );
  });
}
