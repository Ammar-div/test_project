import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'transaction_details.dart';
import 'package:test_project/constants/colors.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() {
    return _TransactionsScreenState();
  }
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedSort = 'Newest';
  final List<String> _sortOptions = ['Newest', 'Oldest', 'Highest Amount', 'Lowest Amount'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: Column(
        children: [
          // Sort Row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: kBackgroundGrey,
            child: Row(
              children: [
                // Sort Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: InputDecoration(
                      labelText: 'Sort',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    ),
                    items: _sortOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSort = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTransactionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No transactions found'));
                }

                final transactions = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(16.r),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index].data() as Map<String, dynamic>;
                    return _buildTransactionCard(transaction, transactions[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    Query query = FirebaseFirestore.instance.collection('transactions');

    // Apply sorting
    switch (_selectedSort) {
      case 'Newest':
      case 'Oldest':
        query = query.orderBy('date', descending: _selectedSort == 'Newest');
        break;
      case 'Highest Amount':
      case 'Lowest Amount':
        query = query.orderBy('amount', descending: _selectedSort == 'Highest Amount');
        break;
    }

    return query.snapshots();
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, String transactionId) {
    // Add null checks for all fields
    final date = transaction['date'] != null 
        ? (transaction['date'] as Timestamp).toDate() 
        : DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
    
    // Handle both int and double amount values with null check
    final amount = transaction['amount'] != null
        ? (transaction['amount'] is int)
            ? (transaction['amount'] as int).toDouble()
            : (transaction['amount'] as double)
        : 0.0;
    
    final status = transaction['status']?.toString().toLowerCase() ?? 'pending';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              transactionId: transactionId,
              transaction: transaction,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16.h),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction #${transactionId.substring(0, 8)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        '${amount.toStringAsFixed(2)} JOD',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = kPrimaryBlue;
        break;
      case 'completed':
        chipColor = Colors.green;
        break;
      case 'failed':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}