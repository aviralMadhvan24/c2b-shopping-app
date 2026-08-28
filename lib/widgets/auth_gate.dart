import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/analytics_provider.dart';
import '../providers/auth_providers.dart';
import '../repositories/app_repositories.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

/// A provider that tracks whether the user chose to continue as a guest.
final guestModeProvider = StateProvider<bool>((ref) => false);

/// AuthGate listens to [authStateProvider] and routes users to the appropriate
/// screen based on authentication state.
///
/// - [AsyncLoading] → loading indicator (max 10s timeout)
/// - [AsyncData(null)] → [LoginScreen] (or [HomeScreen] if guest mode)
/// - [AsyncData(user)] → [HomeScreen]
/// - Timeout after 10s → treat as unauthenticated
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, this.repositories});

  final AppRepositories? repositories;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  Timer? _timeoutTimer;
  bool _timedOut = false;

  /// Built once per State. A getter that constructed `AppRepositories()` on
  /// every call span a fresh `GoogleSignIn` on each build, which made the web
  /// SDK log "google.accounts.id.initialize() is called multiple times" and
  /// then fail with "Future already completed".
  late final AppRepositories _repositories =
      widget.repositories ?? AppRepositories();

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _timedOut = true);
      }
    });
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
  }

  void _enterGuestMode() {
    ref.read(guestModeProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isGuestMode = ref.watch(guestModeProvider);

    return authState.when(
      loading: () {
        // Start timeout timer if not already timed out
        if (!_timedOut) {
          _startTimeout();
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        // Timed out — treat as unauthenticated
        _cancelTimeout();
        return LoginScreen(
          repositories: _repositories,
          onGuestAccess: _enterGuestMode,
        );
      },
      error: (_, _) {
        // On error, treat as unauthenticated
        _cancelTimeout();
        return LoginScreen(
          repositories: _repositories,
          onGuestAccess: _enterGuestMode,
        );
      },
      data: (user) {
        _cancelTimeout();
        // Update analytics user ID based on auth state
        final analytics = ref.read(analyticsServiceProvider);
        if (user != null) {
          analytics.setUserId(user.uid);
          analytics.setCrashlyticsUserContext(
            userId: user.uid,
            isAuthenticated: true,
          );
          // Authenticated user — show HomeScreen
          // Reset guest mode since user is now authenticated
          return HomeScreen(repositories: _repositories);
        }
        // Unauthenticated — clear analytics user ID
        analytics.setUserId(null);
        analytics.setCrashlyticsUserContext(
          userId: null,
          isAuthenticated: false,
        );
        // Unauthenticated — check guest mode
        if (isGuestMode) {
          return HomeScreen(repositories: _repositories);
        }
        return LoginScreen(
          repositories: _repositories,
          onGuestAccess: _enterGuestMode,
        );
      },
    );
  }
}
