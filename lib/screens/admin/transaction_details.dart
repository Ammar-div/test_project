import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';

class TransactionDetailsScreen extends StatelessWidget {
  final String transactionId;
  final Map<String, dynamic> transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
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
    final type = transaction['type']?.toString() ?? 'N/A';
    final senderId = transaction['sender_id']?.toString() ?? 'N/A';
    final receiverId = transaction['receiver_id']?.toString() ?? 'N/A';
    final orderId = transaction['order_id']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction ID
            _buildInfoSection(
              'Transaction ID',
              transactionId,
              Icons.receipt_long,
            ),
            SizedBox(height: 16.h),

            // Amount
            _buildInfoSection(
              'Amount',
              '${amount.toStringAsFixed(2)} JOD',
              Icons.attach_money,
              valueColor: Colors.green[700],
            ),
            SizedBox(height: 16.h),

            // Status
            _buildInfoSection(
              'Status',
              status.toUpperCase(),
              Icons.info_outline,
              valueColor: _getStatusColor(status),
            ),
            SizedBox(height: 16.h),

            // Date
            _buildInfoSection(
              'Date',
              formattedDate,
              Icons.calendar_today,
            ),
            SizedBox(height: 16.h),

            // Type
            _buildInfoSection(
              'Type',
              type,
              Icons.category,
            ),
            SizedBox(height: 16.h),

            // Sender
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(senderId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  return _buildInfoSection(
                    'Sender',
                    userData?['name'] ?? 'Unknown User',
                    Icons.person_outline,
                  );
                }
                return _buildInfoSection(
                  'Sender',
                  'Loading...',
                  Icons.person_outline,
                );
              },
            ),
            SizedBox(height: 16.h),

            // Receiver
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(receiverId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>?;
                  return _buildInfoSection(
                    'Receiver',
                    userData?['name'] ?? 'Unknown User',
                    Icons.person_outline,
                  );
                }
                return _buildInfoSection(
                  'Receiver',
                  'Loading...',
                  Icons.person_outline,
                );
              },
            ),
            SizedBox(height: 16.h),

            // Order ID (if exists)
            if (orderId != null) ...[
              _buildInfoSection(
                'Order ID',
                orderId,
                Icons.shopping_cart_outlined,
              ),
              SizedBox(height: 16.h),
            ],

            // Additional Details
            _buildInfoSection(
              'Additional Details',
              'View all transaction data',
              Icons.more_horiz,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Transaction Data'),
                    content: SingleChildScrollView(
                      child: Text(
                        JsonEncoder.withIndent('  ').convert(transaction),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade800,
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 