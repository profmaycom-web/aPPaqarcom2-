import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for fuchsia - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyuWXN_Kj46m2WGqT4VpaUAsZRrCOVgKk',
    appId: '1:447041223337:android:57a5bd81fe92d1667047b8',
    messagingSenderId: '447041223337',
    projectId: 'aqarcom-broker',
    storageBucket: 'aqarcom-broker.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzQds14yERwU3zWjGW7glxi1KqC1aPY-M',
    appId: '1:447041223337:ios:ef6c46b11ec262d97047b8',
    messagingSenderId: '447041223337',
    projectId: 'aqarcom-broker',
    storageBucket: 'aqarcom-broker.firebasestorage.app',
    androidClientId:
        '447041223337-0ciuk99ou4bc3aq4lrd1qfaj8ohj5fai.apps.googleusercontent.com',
    iosClientId:
        '447041223337-ihrndqdi6ieleldnbjerbrapk3fkr6q3.apps.googleusercontent.com',
    iosBundleId: 'com.aqarcoom.userapp',
  );
}
