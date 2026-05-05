import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

const String _stripePublishableKey =
    String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');

/// Top-level FCM background message handler.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle FCM background messages here once Firebase is configured.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM Background] ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Connected to your real project via SHA fingerprints)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Init failed (GoogleService-Info.plist missing?): $e');
  }

  // Initialize Stripe key from build-time environment.
  if (_stripePublishableKey.trim().isEmpty) {
    if (kReleaseMode) {
      throw StateError(
        'Missing STRIPE_PUBLISHABLE_KEY. Run with --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_...',
      );
    }
    debugPrint(
      '[Stripe] STRIPE_PUBLISHABLE_KEY is not set. Payments will not work until provided via --dart-define.',
    );
  } else {
    Stripe.publishableKey = _stripePublishableKey.trim();
  }

  // Initialize push notifications (Now fully activated via FirebaseMessaging)
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: SophixApp(),
    ),
  );
}

class SophixApp extends StatelessWidget {
  const SophixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sophix',
      debugShowCheckedModeBanner: false,
      theme: buildSophixTheme(),
      // Splash screen is the real entry point — handles auth-aware routing
      home: const SplashScreen(),
    );
  }
}
