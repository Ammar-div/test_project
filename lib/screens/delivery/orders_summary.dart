import 'package:flutter/material.dart';


class OrdersSummary extends StatefulWidget {
  const OrdersSummary({super.key});

  @override
  State<OrdersSummary> createState() => _OrdersSummaryState();
}

class _OrdersSummaryState extends State<OrdersSummary> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('This is Orders Summary'),);
  }
}