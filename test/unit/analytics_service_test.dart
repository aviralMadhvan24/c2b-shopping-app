import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:fashion_store/services/analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late AnalyticsService service;
  late MockFirebaseAnalytics mockAnalytics;
  late MockFirebaseCrashlytics mockCrashlytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    mockCrashlytics = MockFirebaseCrashlytics();
    service = AnalyticsService(
      analytics: mockAnalytics,
      crashlytics: mockCrashlytics,
    );
  });

  group('AnalyticsService - logProductViewed', () {
    test('calls analytics.logEvent with correct name and params', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      service.logProductViewed('prod-123', 'shoes');

      // Allow fire-and-forget future to complete
      await Future<void>.delayed(Duration.zero);

      verify(() => mockAnalytics.logEvent(
            name: 'product_viewed',
            parameters: {
              'product_id': 'prod-123',
              'category': 'shoes',
            },
          )).called(1);
    });
  });

  group('AnalyticsService - logAddToCart', () {
    test('calls analytics.logEvent with correct params (no PII)', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      service.logAddToCart('prod-456', 'var-789', 49.99);

      await Future<void>.delayed(Duration.zero);

      verify(() => mockAnalytics.logEvent(
            name: 'add_to_cart',
            parameters: {
              'product_id': 'prod-456',
              'variant_id': 'var-789',
              'price': 49.99,
            },
          )).called(1);
    });
  });

  group('AnalyticsService - logSearch', () {
    test('truncates query to 256 characters', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      final longQuery = 'a' * 300;
      service.logSearch(longQuery);

      await Future<void>.delayed(Duration.zero);

      verify(() => mockAnalytics.logEvent(
            name: 'search_performed',
            parameters: {
              'query': 'a' * 256,
            },
          )).called(1);
    });

    test('does not truncate query under 256 characters', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async {});

      service.logSearch('red dress');

      await Future<void>.delayed(Duration.zero);

      verify(() => mockAnalytics.logEvent(
            name: 'search_performed',
            parameters: {
              'query': 'red dress',
            },
          )).called(1);
    });
  });

  group('AnalyticsService - setUserId', () {
    test('calls analytics.setUserId with correct uid', () async {
      when(() => mockAnalytics.setUserId(id: any(named: 'id')))
          .thenAnswer((_) async {});

      service.setUserId('user-abc-123');

      await Future<void>.delayed(Duration.zero);

      verify(() => mockAnalytics.setUserId(id: 'user-abc-123')).called(1);
    });
  });

  group('AnalyticsService - silent failure', () {
    test('does not throw when analytics.logEvent throws', () async {
      when(() => mockAnalytics.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) => Future.error(Exception('Network error')));

      // Should not throw
      service.logProductViewed('prod-1', 'tops');

      // Allow fire-and-forget future with error to be caught by catchError
      await Future<void>.delayed(Duration.zero);

      // Verify the call was still attempted
      verify(() => mockAnalytics.logEvent(
            name: 'product_viewed',
            parameters: {
              'product_id': 'prod-1',
              'category': 'tops',
            },
          )).called(1);
    });
  });

  group('AnalyticsService - reportCrash', () {
    test('calls crashlytics.recordError with error and stack trace', () async {
      when(() => mockCrashlytics.recordError(
            any(),
            any(),
            fatal: any(named: 'fatal'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      final error = Exception('Something went wrong');
      final stackTrace = StackTrace.current;

      service.reportCrash(error, stackTrace);

      await Future<void>.delayed(Duration.zero);

      verify(() => mockCrashlytics.recordError(
            error,
            stackTrace,
            fatal: false,
            reason: 'Unhandled exception',
          )).called(1);
    });
  });
}
