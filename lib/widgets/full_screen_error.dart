import 'package:flutter/material.dart';

/// A full-screen error state widget displaying an icon, descriptive message,
/// and a retry button.
///
/// Used when primary screen content fails to load, replacing the screen content
/// entirely. The retry button shows a loading indicator while the operation
/// re-executes.
class FullScreenError extends StatefulWidget {
  /// The error message to display to the user.
  final String message;

  /// The callback to execute when the retry button is tapped.
  final Future<void> Function() onRetry;

  /// The icon to display above the error message.
  final IconData icon;

  /// The color of the icon.
  final Color? iconColor;

  /// Creates a [FullScreenError] widget.
  const FullScreenError({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor,
  });

  @override
  State<FullScreenError> createState() => _FullScreenErrorState();
}

class _FullScreenErrorState extends State<FullScreenError> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 64,
              color: widget.iconColor ?? theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 44,
              child: ElevatedButton(
                onPressed: _isRetrying ? null : _handleRetry,
                child: _isRetrying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
