// Feature: app-completion, Property 10: Error Classification and User Message Safety
// **Validates: Requirements 12.1, 12.2, 12.3, 12.5**
//
// For any error produced by network requests or API calls, the Error_Handler
// SHALL classify it into one of the defined error types (noConnection, timeout,
// apiValidation, notFound, unknown), and the resulting user-facing message SHALL
// NOT contain stack traces, internal error codes, class names, or technical
// implementation details. Additionally, for API validation errors, the displayed
// message SHALL be truncated to a maximum of 200 characters.

import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' hide any;

import 'package:fashion_store/models/app_error.dart';
import 'package:fashion_store/services/error_handler.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

// --- Custom Generators ---

/// Generates random error objects from the variety of errors the app may encounter.
extension ErrorClassificationGenerators on Any {
  /// Generates a random non-empty string for error messages.
  Generator<String> get randomMessage =>
      any.nonEmptyLetterOrDigits.map((s) => s.substring(0, s.length.clamp(0, 300)));

  /// Generates a long string that exceeds 200 characters.
  Generator<String> get longApiMessage => any.letterOrDigits
      .map((s) => 'API error: ${s.padRight(250, 'x')}');

  /// Generates a random error that should classify as one of the defined types.
  Generator<dynamic> get classifiableError => any.choose([
        // SocketException → noConnection
        any.randomMessage.map(
            (msg) => SocketException('Connection failed: $msg')),
        // TimeoutException → timeout
        any.randomMessage
            .map((msg) => TimeoutException('Request timed out: $msg')),
        // General Exception with "API error:" → apiValidation
        any.randomMessage
            .map((msg) => Exception('API error: $msg')),
        // General Exception with "not found" or "404" → notFound
        any.randomMessage.map((msg) => Exception('404 $msg')),
        // General Exception with random message → unknown
        any.randomMessage.map((msg) => Exception('Random failure: $msg')),
        // FormatException → unknown
        any.randomMessage.map((msg) => FormatException(msg)),
        // StateError → unknown
        any.randomMessage.map((msg) => StateError(msg)),
        // ArgumentError → unknown
        any.randomMessage.map((msg) => ArgumentError(msg)),
      ]);
}

/// Patterns that should NEVER appear in user-facing messages.
final _forbiddenPatterns = [
  RegExp(r'Exception'), // Class name
  RegExp(r'Error:'), // Error prefix (technical)
  RegExp(r'#\d+\s+'), // Stack trace frame pattern
  RegExp(r'at \w+\.\w+\('), // Stack trace "at Class.method(" pattern
  RegExp(r'package:'), // Package references from stack traces
  RegExp(r'dart:\w+'), // Dart SDK references
  RegExp(r'\.(dart|js|py):\d+'), // File references with line numbers
  RegExp(r'SocketException'), // Class names
  RegExp(r'TimeoutException'), // Class names
  RegExp(r'FormatException'), // Class names
  RegExp(r'StateError'), // Class names
  RegExp(r'ArgumentError'), // Class names
  RegExp(r'ProductNotFoundException'), // Class names
  RegExp(r'_\w+Error'), // Internal error class naming convention
];

/// All valid AppErrorType values.
final _validErrorTypes = AppErrorType.values.toSet();

ErrorHandler _createHandler() {
  return ErrorHandler(crashlytics: MockFirebaseCrashlytics());
}

void main() {
  group('Property 10: Error Classification and User Message Safety', () {
    Glados(any.classifiableError, ExploreConfig(numRuns: 100)).test(
      'All errors are classified into one of the defined AppErrorType values',
      (error) {
        final handler = _createHandler();
        final appError = handler.classify(error);

        // The classified error type must be one of the defined enum values
        expect(
          _validErrorTypes.contains(appError.type),
          isTrue,
          reason:
              'Error classified as ${appError.type} which is not in defined types',
        );
      },
    );

    Glados(any.classifiableError, ExploreConfig(numRuns: 100)).test(
      'User messages contain no stack traces, class names, or internal codes',
      (error) {
        final handler = _createHandler();
        final appError = handler.classify(error);
        final message = handler.userMessage(appError);

        // Check that none of the forbidden patterns appear in the message
        for (final pattern in _forbiddenPatterns) {
          expect(
            pattern.hasMatch(message),
            isFalse,
            reason:
                'User message "$message" contains forbidden pattern: ${pattern.pattern}',
          );
        }
      },
    );

    Glados(any.longApiMessage, ExploreConfig(numRuns: 100)).test(
      'API validation error messages are truncated to max 200 characters',
      (errorMessage) {
        final handler = _createHandler();

        // Create an exception that will classify as apiValidation
        final error = Exception(errorMessage);
        final appError = handler.classify(error);

        // Verify it's classified as apiValidation
        expect(appError.type, equals(AppErrorType.apiValidation));

        // Get the user message and verify truncation
        final message = handler.userMessage(appError);
        expect(
          message.length,
          lessThanOrEqualTo(200),
          reason:
              'API validation message "$message" exceeds 200 chars (length: ${message.length})',
        );
      },
    );
  });
}
