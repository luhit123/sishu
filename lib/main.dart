import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Recommended for cleaner URLs in Web
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/call_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Recommended for cleaner URLs

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow app to boot even if .env is unavailable in web deployment.
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check
  // TEMPORARILY DISABLED - Firebase rate limiting "Too many attempts" error
  // Re-enable for production builds
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  //   appleProvider: AppleProvider.debug,
  // );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SishuApp());

  // Keep first paint fast; defer network-heavy setup until after UI appears.
  unawaited(_runPostStartupTasks());
}

Future<void> _runPostStartupTasks() async {
  try {
    await NotificationService().initialize();
  } catch (_) {}

  if (kIsWeb) {
    return;
  }

  try {
    await CallService().cleanupStaleCalls();
    await CallService().forceResetCallState();
  } catch (_) {}
}
