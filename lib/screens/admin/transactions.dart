import 'package:flutter/material.dart';



class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() {
    return _TransactionsScreenState();
  }
}

class _TransactionsScreenState extends State<TransactionsScreen> {

  @override
  Widget build(BuildContext context) {
    return const Text('this is transaction page');
  }
}