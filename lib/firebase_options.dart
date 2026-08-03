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
      default:
        return windows;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCWLzBssj6jevxtOXMUPZnam7ZuzoIUveg',
    appId: '1:287903170664:web:03e990f137ba0f666a7bdd',
    messagingSenderId: '287903170664',
    projectId: 'littlejohorexplorer-9ae9c',
    authDomain: 'littlejohorexplorer-9ae9c.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB777_GDveFzUWVkCTavEUgoprGzAwgja8',
    appId: '1:287903170664:android:5b3d2212abe1eafa6a7bdd',
    messagingSenderId: '287903170664',
    projectId: 'littlejohorexplorer-9ae9c',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCXh2TTXRvWd8UtfcFdGRGrv84fN4EdpG4',
    appId: '1:287903170664:ios:2ba299a97bce06106a7bdd',
    messagingSenderId: '287903170664',
    projectId: 'littlejohorexplorer-9ae9c',
    iosBundleId: 'com.example.littleJohorExplorer',
  );

  static FirebaseOptions get macos => ios;
  static FirebaseOptions get windows => web;
}
