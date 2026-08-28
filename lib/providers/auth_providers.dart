import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';

/// Provides the singleton AuthRepository instance.
final authServiceProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Exposes the Firebase Auth state as a stream.
/// Emits the current [User] when authenticated, or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
