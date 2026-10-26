import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const OmrScannerApp());
}

class OmrScannerApp extends StatelessWidget {
  const OmrScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OMR Scanner',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const HomeScreen(),
    );
  }
}
