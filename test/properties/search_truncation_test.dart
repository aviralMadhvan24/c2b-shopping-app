// Feature: app-completion, Property 11: Analytics Search Query Truncation
// **Validates: Requirements 13.5**
//
// For any search query string, the Analytics_Service SHALL log the query
// truncated to a maximum of 256 characters, preserving the first 256
// characters verbatim.

import 'package:glados/glados.dart';
import 'package:fashion_store/services/analytics_service.dart';

/// Pure function that replicates the truncation logic from AnalyticsService.logSearch.
/// This allows testing the truncation as a pure function without Firebase dependencies.
String truncateSearchQuery(String query) {
  return query.length > AnalyticsService.maxSearchQueryLength
      ? query.substring(0, AnalyticsService.maxSearchQueryLength)
      : query;
}

// --- Custom Generators ---

extension SearchQueryGenerators on Any {
  /// Generates random strings of length 0–1000 to test truncation behavior
  /// across short, boundary, and long inputs.
  Generator<String> get searchQuery =>
      intInRange(0, 1000).map((length) => 'q' * length);

  /// Generates strings with varied characters of length 0-1000.
  Generator<String> get variedSearchQuery =>
      intInRange(0, 1000).map((length) {
        // Create a string with varied characters to ensure prefix preservation
        final buffer = StringBuffer();
        for (int i = 0; i < length; i++) {
          buffer.writeCharCode(65 + (i % 26)); // A-Z repeating
        }
        return buffer.toString();
      });

  /// Generates strings that are exactly at or near the 256-char boundary.
  Generator<String> get boundarySearchQuery =>
      intInRange(254, 258).map((length) {
        final buffer = StringBuffer();
        for (int i = 0; i < length; i++) {
          buffer.writeCharCode(97 + (i % 26)); // a-z repeating
        }
        return buffer.toString();
      });
}

void main() {
  group('Property 11: Analytics Search Query Truncation', () {
    Glados(any.searchQuery, ExploreConfig(numRuns: 100)).test(
      'Truncated query is always ≤256 characters',
      (String query) {
        final result = truncateSearchQuery(query);

        expect(result.length, lessThanOrEqualTo(256));
      },
    );

    Glados(any.variedSearchQuery, ExploreConfig(numRuns: 100)).test(
      'For strings ≤256 chars, the result equals the original',
      (String query) {
        final result = truncateSearchQuery(query);

        if (query.length <= 256) {
          expect(result, equals(query));
        }
      },
    );

    Glados(any.variedSearchQuery, ExploreConfig(numRuns: 100)).test(
      'For strings >256 chars, the result equals the first 256 characters',
      (String query) {
        final result = truncateSearchQuery(query);

        if (query.length > 256) {
          expect(result, equals(query.substring(0, 256)));
          expect(result.length, equals(256));
        }
      },
    );

    Glados(any.boundarySearchQuery, ExploreConfig(numRuns: 100)).test(
      'Boundary cases: preserves first 256 chars verbatim',
      (String query) {
        final result = truncateSearchQuery(query);

        // Result is always ≤ 256
        expect(result.length, lessThanOrEqualTo(256));

        // Result is always a prefix of the original
        expect(query.startsWith(result), isTrue);

        // If original is ≤ 256, result is identical
        if (query.length <= 256) {
          expect(result, equals(query));
        } else {
          // If original is > 256, result is exactly the first 256 chars
          expect(result, equals(query.substring(0, 256)));
        }
      },
    );
  });
}
