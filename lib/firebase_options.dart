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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_Q43wQxA2VyDSqgiQtoAY9bwkhr1saHo',
    appId: '1:1016498515081:web:699a2a0bcf0a0765902a58',
    messagingSenderId: '1016498515081',
    projectId: 'little-johor-explorer-db',
    authDomain: 'little-johor-explorer-db.firebaseapp.com',
    storageBucket: 'little-johor-explorer-db.firebasestorage.app',
    measurementId: 'G-0G7TDVB0P3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtOUweOMApF0xBH7KLKGI09N7vOZtjUZM',
    appId: '1:1016498515081:android:0f511bcb1879790b902a58',
    messagingSenderId: '1016498515081',
    projectId: 'little-johor-explorer-db',
    storageBucket: 'little-johor-explorer-db.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDhZxCaj4EIF57apWJyLcuSdreuUwrLH_g',
    appId: '1:1016498515081:ios:3e450c7a108acf7c902a58',
    messagingSenderId: '1016498515081',
    projectId: 'little-johor-explorer-db',
    storageBucket: 'little-johor-explorer-db.firebasestorage.app',
    iosBundleId: 'com.littlejohorexplorer.app',
  );

  static FirebaseOptions get macos => ios;
  static FirebaseOptions get windows => web;
}
