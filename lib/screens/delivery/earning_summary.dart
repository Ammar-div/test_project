import 'package:flutter/material.dart';
import 'package:test_project/constants/colors.dart';

class EarningSummary extends StatefulWidget {
  const EarningSummary({super.key});

  @override
  State<EarningSummary> createState() => _EarningSummaryState();
}

class _EarningSummaryState extends State<EarningSummary> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: Center(
        child: Text(
          'this is Earning Summary page',
          style: TextStyle(color: kPrimaryBlue),
        ),
      ),
    );
  }
}