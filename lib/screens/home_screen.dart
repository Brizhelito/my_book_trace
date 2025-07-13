import 'package:flutter/material.dart';
import 'package:MyBookTrace/widgets/home_content.dart';

/// Pantalla de inicio con AppBar independiente
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyBookTrace'), elevation: 1),
      body: const HomeContent(),
    );
  }
}
