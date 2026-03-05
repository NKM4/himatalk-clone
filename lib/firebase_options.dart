// Firebase configuration for HimaTalk+ Clone
// Generated from google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web configuration (uses same API key as Android for now)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATGgLGb6h2kYRhKSirKH3NeU0XsGNHNn8',
    appId: '1:35694804745:android:cc735f0586668769cc9dd8',
    messagingSenderId: '35694804745',
    projectId: 'himatalk-clone',
    authDomain: 'himatalk-clone.firebaseapp.com',
    storageBucket: 'himatalk-clone.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATGgLGb6h2kYRhKSirKH3NeU0XsGNHNn8',
    appId: '1:35694804745:android:cc735f0586668769cc9dd8',
    messagingSenderId: '35694804745',
    projectId: 'himatalk-clone',
    storageBucket: 'himatalk-clone.firebasestorage.app',
  );

  // iOS configuration (placeholder - need to add iOS app in Firebase Console)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATGgLGb6h2kYRhKSirKH3NeU0XsGNHNn8',
    appId: '1:35694804745:android:cc735f0586668769cc9dd8',
    messagingSenderId: '35694804745',
    projectId: 'himatalk-clone',
    storageBucket: 'himatalk-clone.firebasestorage.app',
    iosBundleId: 'com.example.himatalkClone',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyATGgLGb6h2kYRhKSirKH3NeU0XsGNHNn8',
    appId: '1:35694804745:android:cc735f0586668769cc9dd8',
    messagingSenderId: '35694804745',
    projectId: 'himatalk-clone',
    storageBucket: 'himatalk-clone.firebasestorage.app',
    iosBundleId: 'com.example.himatalkClone',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyATGgLGb6h2kYRhKSirKH3NeU0XsGNHNn8',
    appId: '1:35694804745:android:cc735f0586668769cc9dd8',
    messagingSenderId: '35694804745',
    projectId: 'himatalk-clone',
    authDomain: 'himatalk-clone.firebaseapp.com',
    storageBucket: 'himatalk-clone.firebasestorage.app',
  );
}
