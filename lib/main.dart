import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/launcher_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI for edge-to-edge on Android 15+
  // Using transparent overlays instead of deprecated setSystemUIOverlayStyle
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEND-IT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo[700]!,
          secondary: Colors.indigo[200]!,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.indigo[50],
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.indigo[900]),
          bodyMedium: TextStyle(color: Colors.indigo[700]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[600],
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const LauncherScreen(),
    );
  }
}
