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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD6tswgwEL-2hEjL-_-Qub4uP5PdMEWNoo',
    appId: '1:994797339321:web:c5b9be894c57f8c4489168',
    messagingSenderId: '994797339321',
    projectId: 'rentrecipy',
    authDomain: 'rentrecipy.firebaseapp.com',
    storageBucket: 'rentrecipy.firebasestorage.app',
    measurementId: 'G-XKXW98DE8H',
  );

  // TODO: In Firebase Console → Project Settings → Add Android app
  // Package name: com.example.rent_receipt_manager
  // Then replace the appId below with the one from google-services.json.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6tswgwEL-2hEjL-_-Qub4uP5PdMEWNoo',
    appId: '1:994797339321:android:REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '994797339321',
    projectId: 'rentrecipy',
    storageBucket: 'rentrecipy.firebasestorage.app',
  );

  // TODO: In Firebase Console → Project Settings → Add iOS app
  // Bundle ID: com.example.rentReceiptManager
  // Then replace the appId and iosClientId below.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6tswgwEL-2hEjL-_-Qub4uP5PdMEWNoo',
    appId: '1:994797339321:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '994797339321',
    projectId: 'rentrecipy',
    storageBucket: 'rentrecipy.firebasestorage.app',
    iosClientId: 'REPLACE_WITH_IOS_CLIENT_ID',
    iosBundleId: 'com.example.rentReceiptManager',
  );
}
