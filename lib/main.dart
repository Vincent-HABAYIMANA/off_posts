// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/post_list_screen.dart';

void main() {
  runApp(const OfflinePostsApp());
}

class OfflinePostsApp extends StatelessWidget {
  const OfflinePostsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Posts Manager',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // Input fields style
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF5F5F5),
        ),

        // ✅ FIXED cardTheme (safe version)
        cardTheme: const CardThemeData(
          elevation: 2,
        ),

        // Buttons style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      home: const PostListScreen(),
    );
  }
}