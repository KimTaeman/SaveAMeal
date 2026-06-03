// ignore: unused_import — uncomment FirestoreEmulator line below to activate
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:saveameal/app/app.dart';
import 'package:saveameal/firebase_options.dart';

/// Top-level function required by Firebase Messaging — must NOT be a class
/// method. Runs in a separate isolate when a notification arrives while the
/// app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Re-initialize Firebase because this runs in a separate isolate.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // No UI — the system tray already shows the notification.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must be called before runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    // Toggle: comment the line below to use live Firestore instead of the emulator.
    // Start emulator: firebase emulators:start --only firestore
    // Seed data:      cd tools/seed && npm run seed:clean
    // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<dynamic>('donor_batches'),
    Hive.openBox<dynamic>('donor_metrics'),
    Hive.openBox<dynamic>('driver_profile'),
  ]);

  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const ProviderScope(child: App()));
}
