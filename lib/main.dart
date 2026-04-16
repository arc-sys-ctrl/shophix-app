import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

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

  // Initialize Stripe
  Stripe.publishableKey = 'pk_test_placeholder_for_sophix_stripe';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        primaryColor: const Color(0xFF00D1FF),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D1FF),
          secondary: Color(0xFF1E2832),
          surface: Color(0xFF0A0E14),
        ),
        useMaterial3: true,
      ),
      // Splash screen is the real entry point — handles auth-aware routing
      home: const SplashScreen(),
    );
  }
}
