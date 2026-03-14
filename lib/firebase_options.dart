import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios; // reuse iOS config for macOS
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtNMA5u0Z13guBK2e-Vx5x9hmawHu59a8',
    appId: '1:141207767820:web:50682876fbf825d567d729',
    messagingSenderId: '141207767820',
    projectId: 'awra-spinwheel',
    authDomain: 'awra-spinwheel.firebaseapp.com',
    storageBucket: 'awra-spinwheel.firebasestorage.app',
    measurementId: 'G-51HMY0PJP1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4T6040KLCikG-jWKe2YRY6HYzCRQlG2c',
    appId: '1:141207767820:android:20c6f20cef6a32c867d729',
    messagingSenderId: '141207767820',
    projectId: 'awra-spinwheel',
    storageBucket: 'awra-spinwheel.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDVxZQ57Wvt6Bt08VHXjjYjMTsVrcljo28',
    appId: '1:141207767820:ios:ac18c47c6c5f2ddf67d729',
    messagingSenderId: '141207767820',
    projectId: 'awra-spinwheel',
    storageBucket: 'awra-spinwheel.firebasestorage.app',
    iosBundleId: 'com.awra.spinwheel',
  );
}
