import 'package:flutter/material.dart';
import 'package:test_project/constants/colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: Center(
        child: CircularProgressIndicator(
          color: kPrimaryBlue,
        ),
      ),
    );
  }
}