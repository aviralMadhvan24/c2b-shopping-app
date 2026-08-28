import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable inline non-blocking error display using a SnackBar.
///
/// Shows an error message and optional retry action without interrupting
/// the user's current workflow.
class ErrorSnackBar {
  /// Shows an error snackbar with the given [message].
  ///
  /// Optionally accepts an [onRetry] callback to display a retry action.
  /// The [duration] defaults to 4 seconds.
  static void show(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textDark),
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: AppColors.textDark,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}
