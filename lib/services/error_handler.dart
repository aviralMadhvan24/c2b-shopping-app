import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../models/app_error.dart';
import '../repositories/product_repository.dart';

/// Centralized error handler that classifies errors, generates user-friendly
/// messages, and reports unknown errors to Crashlytics.
class ErrorHandler {
  /// The Crashlytics instance used for error reporting.
  final FirebaseCrashlytics _crashlytics;

  /// Network timeout threshold in seconds.
  static const int timeoutThresholdSeconds = 15;

  /// Maximum length for API validation error messages.
  static const int maxApiMessageLength = 200;

  /// Creates an [ErrorHandler] instance.
  ///
  /// Optionally accepts a [FirebaseCrashlytics] instance for testing.
  ErrorHandler({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  /// Classifies a dynamic error into an [AppError] with a specific [AppErrorType].
  ///
  /// Classification rules:
  /// - [SocketException] / connectivity issues → [AppErrorType.noConnection]
  /// - [TimeoutException] / HTTP timeout (>15s) → [AppErrorType.timeout]
  /// - Backend validation errors → [AppErrorType.apiValidation]
  /// - HTTP 404 / [ProductNotFoundException] → [AppErrorType.notFound]
  /// - All other errors → [AppErrorType.unknown]
  AppError classify(dynamic error) {
    if (error is AppError) {
      return error;
    }

    if (error is SocketException) {
      return AppError(
        type: AppErrorType.noConnection,
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return AppError(
        type: AppErrorType.timeout,
        originalError: error,
      );
    }

    if (error is ProductNotFoundException) {
      return AppError(
        type: AppErrorType.notFound,
        originalError: error,
      );
    }

    // Check for exception messages that indicate specific error types
    final errorString = error.toString();

    // Check for HTTP timeout patterns
    if (_isTimeoutError(errorString)) {
      return AppError(
        type: AppErrorType.timeout,
        originalError: error,
      );
    }

    // Check for no connection patterns
    if (_isConnectionError(errorString)) {
      return AppError(
        type: AppErrorType.noConnection,
        originalError: error,
      );
    }

    // Check for 404 / not found patterns
    if (_isNotFoundError(errorString)) {
      return AppError(
        type: AppErrorType.notFound,
        originalError: error,
      );
    }

    // Check for backend validation errors
    if (_isApiValidationError(errorString)) {
      final message = _extractApiMessage(errorString);
      return AppError(
        type: AppErrorType.apiValidation,
        apiMessage: _truncateMessage(message, maxApiMessageLength),
        originalError: error,
      );
    }

    return AppError(
      type: AppErrorType.unknown,
      originalError: error,
    );
  }

  /// Returns a user-friendly message for the given [AppError].
  ///
  /// Messages never expose stack traces, internal error codes, or technical
  /// implementation details.
  String userMessage(AppError error) {
    switch (error.type) {
      case AppErrorType.noConnection:
        return 'No internet connection';
      case AppErrorType.timeout:
        return 'Request timed out';
      case AppErrorType.apiValidation:
        if (error.apiMessage != null && error.apiMessage!.isNotEmpty) {
          return _truncateMessage(error.apiMessage!, maxApiMessageLength);
        }
        return 'A validation error occurred. Please try again.';
      case AppErrorType.notFound:
        return 'Product not available';
      case AppErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Reports an error to Firebase Crashlytics.
  ///
  /// Only unknown/unexpected errors are reported. Known/expected errors
  /// (no connection, timeout) are NOT reported to Crashlytics.
  ///
  /// This method never throws — reporting failures are silently discarded.
  Future<void> report(dynamic error, StackTrace stackTrace) async {
    try {
      final appError = error is AppError ? error : classify(error);

      // Only report unknown errors to Crashlytics
      if (appError.type == AppErrorType.unknown) {
        await _crashlytics.recordError(
          appError.originalError ?? error,
          stackTrace,
          reason: 'Unhandled error',
          fatal: false,
        );
      }
    } catch (_) {
      // Silently discard reporting failures — never block the UI
    }
  }

  /// Checks if the error string indicates a timeout.
  bool _isTimeoutError(String errorString) {
    final lower = errorString.toLowerCase();
    return lower.contains('timeout') || lower.contains('timed out');
  }

  /// Checks if the error string indicates a connectivity issue.
  bool _isConnectionError(String errorString) {
    final lower = errorString.toLowerCase();
    return lower.contains('no internet') ||
        lower.contains('no address associated') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('socketexception') ||
        lower.contains('no route to host');
  }

  /// Checks if the error string indicates a 404/not found error.
  bool _isNotFoundError(String errorString) {
    final lower = errorString.toLowerCase();
    return lower.contains('404') ||
        lower.contains('not found') ||
        lower.contains('productnotfoundexception');
  }

  /// Checks if the error string indicates a backend validation error.
  bool _isApiValidationError(String errorString) {
    final lower = errorString.toLowerCase();
    return lower.contains('validation error') || lower.contains('api error');
  }

  /// Extracts the API message from an error string.
  String _extractApiMessage(String errorString) {
    // Try to extract message after common prefixes
    final patterns = [
      'API error: ',
      'Validation error: ',
      'Exception: API error: ',
      'Exception: Validation error: ',
    ];

    for (final pattern in patterns) {
      final index = errorString.indexOf(pattern);
      if (index != -1) {
        return errorString.substring(index + pattern.length).trim();
      }
    }

    // Fall back to the whole error string, cleaned up
    return errorString
        .replaceAll(RegExp(r'^Exception:\s*'), '')
        .trim();
  }

  /// Truncates a message to the specified max length, adding ellipsis if needed.
  String _truncateMessage(String message, int maxLength) {
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength - 3)}...';
  }
}
