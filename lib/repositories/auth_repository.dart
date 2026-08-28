import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _googleWebClientId =
    '847222172281-ctqogfeengmpvtp04d4065pb927qbfs3.apps.googleusercontent.com';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn? _injectedGoogleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _injectedGoogleSignIn = googleSignIn;

  /// Created on first use rather than in the constructor: instantiating
  /// [GoogleSignIn] on web immediately boots Google Identity Services, and
  /// web signs in through [FirebaseAuth.signInWithPopup] instead — so the
  /// GIS bootstrap is pure overhead there (and logs "initialize() is called
  /// multiple times" when repositories are rebuilt).
  late final GoogleSignIn _googleSignIn = _injectedGoogleSignIn ??
      GoogleSignIn(
        serverClientId: _googleWebClientId,
        scopes: const ['email', 'profile'],
      );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      await _createUserProfile(credential.user!, name);
    }

    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final userCredential =
        kIsWeb ? await _signInWithGoogleWeb() : await _signInWithGoogleMobile();
    if (userCredential == null) return null;

    final user = userCredential.user;
    if (user != null) {
      // Check if profile exists, if not create it
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _createUserProfile(user, user.displayName ?? 'Google User');
      }
    }

    return userCredential;
  }

  /// On web, `google_sign_in`'s `signIn()` is deprecated and cannot reliably
  /// return an `idToken` — it opens a token-only popup that fails with
  /// `popup_closed`. Firebase Auth's own popup flow is the supported path and
  /// yields a credential directly.
  Future<UserCredential?> _signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');
    try {
      return await _auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      // The user dismissing the popup is a cancellation, not a failure.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'user-cancelled') {
        return null;
      }
      rethrow;
    }
  }

  Future<UserCredential?> _signInWithGoogleMobile() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> _createUserProfile(User user, String name) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': user.email,
      'phone': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'defaultAddressId': null,
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // Only meaningful where google_sign_in actually performed the sign-in;
    // on web that is Firebase's popup flow, so there is no GIS session to
    // clear and touching it would needlessly boot the library.
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}
