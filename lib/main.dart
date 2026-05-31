import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helmet_app/features/dashboard/dashboard.dart';

import 'package:helmet_app/features/navigation/maps.dart';
import 'package:helmet_app/features/grid_screen/grid_screen.dart';
import 'package:helmet_app/features/voice_assistant/wake_word_service.dart';
import 'package:helmet_app/features/settings/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env.local");
  
  // Initialize background wake word listener
  await WakeWordService.instance.initialize();
  await WakeWordService.instance.startListening();

  // Initialize Settings
  await SettingsService.instance.init();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showSemanticsDebugger: false,
      title: 'Helmet App',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white,),
          bodyLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white70),
        ),
      ),
      routes: {
        '/grid_screen': (context) => const GridScreen(),
        '/maps': (context) => const MapsScreen(),
      },
      home: const DashboardScreen(),
    );
  }
}

