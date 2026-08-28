import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';

/// Provides the singleton AnalyticsService instance throughout the app.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
