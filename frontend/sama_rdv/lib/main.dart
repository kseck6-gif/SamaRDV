import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

const samaBlue = Color(0xFF1769AA);
const samaLightBlue = Color(0xFFDCEEFF);

void main() => runApp(const SamaRDVApp());

class SamaRDVApp extends StatelessWidget {
  const SamaRDVApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: samaBlue, primary: samaBlue);
    return MaterialApp(
      title: 'SamaRDV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF6F9FD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: samaBlue,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: samaBlue, fontSize: 21, fontWeight: FontWeight.w800),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: samaBlue.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2EAF3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2EAF3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: samaBlue, width: 1.5)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: samaBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: samaBlue),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
