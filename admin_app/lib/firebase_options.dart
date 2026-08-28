// Firebase configuration for the Niyati Mart admin console.
//
// This points at the SAME Firebase project as the customer app
// (c2b-shopping-app), which is the whole point: the admin edits the very
// documents the storefront reads. Values are copied from
// ../lib/firebase_options.dart.
//
// The admin console ships for web only, so `currentPlatform` returns the web
// options. Add another branch here if you later run `flutter create
// --platforms=android .` inside this directory.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'The Niyati admin console is configured for web (and Android). '
          'Run `flutterfire configure` in admin_app/ to add this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDYriBjAp6Fz4Yne4tWWmOMu0tga8clq5A',
    appId: '1:847222172281:web:e879534a16667be4bf82a8',
    messagingSenderId: '847222172281',
    projectId: 'c2b-shopping-app',
    authDomain: 'c2b-shopping-app.firebaseapp.com',
    storageBucket: 'c2b-shopping-app.firebasestorage.app',
    measurementId: 'G-ZXCY482JVV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAA-lxHC_my64jRjAGRwpp9FyAE7Gt_evg',
    appId: '1:847222172281:android:dc5cdaaab3f8ee20bf82a8',
    messagingSenderId: '847222172281',
    projectId: 'c2b-shopping-app',
    storageBucket: 'c2b-shopping-app.firebasestorage.app',
  );
}
