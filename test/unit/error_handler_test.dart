import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fashion_store/models/app_error.dart';
import 'package:fashion_store/repositories/product_repository.dart';
import 'package:fashion_store/services/error_handler.dart';

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late ErrorHandler errorHandler;
  late MockFirebaseCrashlytics mockCrashlytics;

  setUp(() {
    mockCrashlytics = MockFirebaseCrashlytics();
    errorHandler = ErrorHandler(crashlytics: mockCrashlytics);
  });

  group('ErrorHandler.classify', () {
    test('SocketException is classified as noConnection', () {
      final error = const SocketException('No internet');
      final result = errorHandler.classify(error);

      expect(result.type, AppErrorType.noConnection);
    });

    test('TimeoutException is classified as timeout', () {
      final error = TimeoutException('Connection timed out');
      final result = errorHandler.classify(error);

      expect(result.type, AppErrorType.timeout);
    });

    test(
        'Exception with "API error: ..." is classified as apiValidation',
        () {
      final error = Exception('API error: Invalid product ID');
      final result = errorHandler.classify(error);

      expect(result.type, AppErrorType.apiValidation);
      expect(result.apiMessage, 'Invalid product ID');
    });

    test('ProductNotFoundException is classified as notFound', () {
      final error = ProductNotFoundException('prod-123');
      final result = errorHandler.classify(error);

      expect(result.type, AppErrorType.notFound);
    });

    test('Random exception is classified as unknown', () {
      final error = Exception('Some random error');
      final result = errorHandler.classify(error);

      expect(result.type, AppErrorType.unknown);
    });
  });

  group('ErrorHandler.userMessage', () {
    test('noConnection returns "No internet connection"', () {
      final error = errorHandler.classify(const SocketException('test'));
      expect(errorHandler.userMessage(error), 'No internet connection');
    });

    test('timeout returns "Request timed out"', () {
      final error = errorHandler.classify(TimeoutException('test'));
      expect(errorHandler.userMessage(error), 'Request timed out');
    });

    test('apiValidation returns the API message', () {
      final error =
          errorHandler.classify(Exception('API error: Bad input'));
      expect(errorHandler.userMessage(error), 'Bad input');
    });

    test('notFound returns "Product not available"', () {
      final error =
          errorHandler.classify(ProductNotFoundException('prod-123'));
      expect(errorHandler.userMessage(error), 'Product not available');
    });

    test('unknown returns "Something went wrong. Please try again."', () {
      final error = errorHandler.classify(Exception('Some random error'));
      expect(
          errorHandler.userMessage(error), 'Something went wrong. Please try again.');
    });

    test('API validation message is truncated to 200 chars when longer', () {
      final longMessage = 'A' * 250;
      final error = errorHandler
          .classify(Exception('API error: $longMessage'));
      final message = errorHandler.userMessage(error);

      expect(message.length, 200);
      expect(message.endsWith('...'), isTrue);
    });
  });

  group('ErrorHandler.report', () {
    test('reports unknown errors to Crashlytics', () async {
      when(() => mockCrashlytics.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          )).thenAnswer((_) async {});

      final error = Exception('Unexpected failure');
      await errorHandler.report(error, StackTrace.current);

      verify(() => mockCrashlytics.recordError(
            any(),
            any(),
            reason: 'Unhandled error',
            fatal: false,
          )).called(1);
    });

    test('does not report noConnection errors to Crashlytics', () async {
      final error = const SocketException('No internet');
      await errorHandler.report(error, StackTrace.current);

      verifyNever(() => mockCrashlytics.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ));
    });

    test('does not report timeout errors to Crashlytics', () async {
      final error = TimeoutException('Timed out');
      await errorHandler.report(error, StackTrace.current);

      verifyNever(() => mockCrashlytics.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ));
    });

    test('does not report notFound errors to Crashlytics', () async {
      final error = ProductNotFoundException('prod-1');
      await errorHandler.report(error, StackTrace.current);

      verifyNever(() => mockCrashlytics.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ));
    });

    test('does not report apiValidation errors to Crashlytics', () async {
      final error = Exception('API error: Bad request');
      await errorHandler.report(error, StackTrace.current);

      verifyNever(() => mockCrashlytics.recordError(
            any(),
            any(),
            reason: any(named: 'reason'),
            fatal: any(named: 'fatal'),
          ));
    });
  });
}
