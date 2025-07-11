import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEND-IT',
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
      home: HomePage(),
    );
  }
}
