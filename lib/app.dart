import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helmet_app/features/authentication/screens/login/login.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helmet App',

      // 🌙 Global Theme
      theme: ThemeData(
        useMaterial3: true,

        // Primary font (Google Sans Flex)
        textTheme: GoogleFonts.getTextTheme(
          'Google Sans Flex',
        ).copyWith(
          // Headings → Montserrat
          headlineLarge: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),

          // Buttons / labels → Bitcount Prop Single
          headlineMedium: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}