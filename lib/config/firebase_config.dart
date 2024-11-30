// lib/config/firebase_config.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:poker_tracker/config/env_config.dart';

class FirebaseConfig {
  static FirebaseOptions get _options => FirebaseOptions(
        apiKey: EnvironmentConfig.firebaseApiKey,
        appId: EnvironmentConfig.firebaseAppId,
        messagingSenderId: EnvironmentConfig.firebaseMessagingSenderId,
        projectId: EnvironmentConfig.firebaseProjectId,
        measurementId: EnvironmentConfig.firebaseMeasurementId,
      );

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        name: 'poker_tracker',
        options: _options,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      rethrow;
    }
  }
}
