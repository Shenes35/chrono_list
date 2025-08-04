import 'package:flutter/material.dart';
import 'package:chrono_list/presentation/splash_screen.dart';
import 'dart:developer';
void main() {
// Waits for debugger to attach before continuing
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Center(child: SplashScreen()),
    );
  }
}
