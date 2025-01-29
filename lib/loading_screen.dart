import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 242, 223, 214),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}