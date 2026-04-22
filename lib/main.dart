import 'package:flutter/material.dart';

import 'screens/service_selection_screen.dart';

void main() {
  runApp(const SelfRivalApp());
}

class SelfRivalApp extends StatelessWidget {
  const SelfRivalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Rival',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ServiceSelectionScreen(),
    );
  }
}
