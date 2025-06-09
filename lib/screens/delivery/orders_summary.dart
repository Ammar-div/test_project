import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_project/constants/colors.dart';
import 'order_details.dart';

class OrdersSummary extends StatefulWidget {
  const OrdersSummary({super.key});

  @override
  State<OrdersSummary> createState() => _OrdersSummaryState();
}

class _OrdersSummaryState extends State<OrdersSummary> {
  String getCurrentDeliveryCaptainId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('delivery_person_id', isEqualTo: getCurrentDeliveryCaptainId())
        .where('status', isEqualTo: 'delivered')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundGrey,
      body: StreamBuilder<QuerySnapshot>(
        stream: _getOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.only(top: 32.h, left: 16.r, right: 16.r, bottom: 16.r),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              return _buildOrderCard(order, orders[index].id);
            }, 
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String orderId) {
    final deliveredDate = order['delivered_date'] != null 
        ? (order['delivered_date'] as Timestamp).toDate() 
        : DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(deliveredDate);
    
    final amount = order['product_infos']?['total_amount']?.toDouble() ?? 0.0;
    final status = order['status']?.toString().toLowerCase() ?? 'pending';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(
              orderId: orderId,
              order: order,
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
                    'Order #${orderId.substring(0, 8)}',
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
      case 'delivered':
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