import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Who is allowed into the console.
///
/// Authentication is plain Firebase email/password — the same user pool the
/// storefront uses. Authorisation is a separate document at `admins/{uid}`
/// with `active: true`. Signing in is therefore not enough: a shopper who
/// somehow reaches this URL authenticates fine and is then bounced, and the
/// Firestore rules enforce the same check server-side so a bounced session
/// cannot write anything either.
///
/// Bootstrapping the first admin is a one-time manual step in the Firebase
/// console — see admin_app/README.md.
class AdminAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Live view of the signed-in user's admin record. Streaming rather than a
  /// one-shot read so that revoking access (flipping `active` to false) takes
  /// effect on an open session without waiting for a reload.
  Stream<AdminUser?> watchAdmin(String uid) {
    return _firestore.collection('admins').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AdminUser.fromMap(uid, doc.data() ?? const {});
    });
  }

  /// Turns a FirebaseAuthException into something a shop owner can act on.
  static String describeAuthError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'That email address is not valid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Wrong email or password.',
        'too-many-requests' =>
          'Too many attempts. Wait a minute and try again.',
        'network-request-failed' =>
          'No connection. Check your internet and try again.',
        _ => error.message ?? 'Could not sign in. Please try again.',
      };
    }
    return 'Could not sign in. Please try again.';
  }
}

/// The `admins/{uid}` record.
class AdminUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool active;

  const AdminUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'owner',
    this.active = true,
  });

  factory AdminUser.fromMap(String uid, Map<String, dynamic> map) => AdminUser(
        uid: uid,
        name: map['name'] as String? ?? 'Admin',
        email: map['email'] as String? ?? '',
        role: map['role'] as String? ?? 'owner',
        active: map['active'] as bool? ?? true,
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
  }
}
