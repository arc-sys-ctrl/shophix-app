import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
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
      title: 'Sophix DRPSTR',
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
          background: Color(0xFF0A0E14),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
